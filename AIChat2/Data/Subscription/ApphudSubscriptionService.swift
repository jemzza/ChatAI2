import ApphudSDK
import Foundation
import StoreKit

@MainActor
final class ApphudSubscriptionService: SubscribableService {
    static let paywallID = "main"
    static let paywallProductIDs = ["week_4.99_nottrial", "year_39.99_nottrial"]
    
    private let premium: Broadcast<Bool>
    private var updatesTask: Task<Void, Never>?
    private var paywall: ApphudPaywall?
    private var groupProducts: [Product.ID: Product] = [:]
    
    init(apiKey: String) {
#if DEBUG
        Apphud.enableDebugLogs()
#endif
        Apphud.start(apiKey: apiKey)
        premium = Broadcast(Apphud.hasPremiumAccess())
        updatesTask = Task { [weak self] in
            await self?.refresh()
            for await _ in NotificationCenter.default.notifications(named: Apphud.didUpdateNotification()) {
                await self?.refresh()
            }
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    var isPremium: Bool { premium.value }
    
    func premiumUpdates() -> AsyncStream<Bool> { premium.updates() }
    
    var userID: String { Apphud.userID() }
    
    func paywallPlans() async throws(SubscriptionError) -> [SubscriptionPlan] {
        let placements = await Apphud.placements()
        paywall = placements.lazy.compactMap(\.paywall).first { $0.identifier == Self.paywallID }
            ?? placements.first { $0.identifier == Self.paywallID }?.paywall
        
        groupProducts = [:]
        let products: [Product]
        if let paywall {
            var loaded: [Product] = []
            for product in paywall.products {
                if let storeProduct = try? await product.product() { loaded.append(storeProduct) }
            }
            products = loaded
        } else {
            products = await productsFromPermissionGroups()
            groupProducts = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        guard !products.isEmpty else { throw .productsUnavailable }
        return products.map(Self.plan(from:))
    }
    
    func paywallShown() {
        if let paywall { Apphud.paywallShown(paywall) }
    }
    
    func purchase(planID: SubscriptionPlan.ID) async throws(SubscriptionError) -> PurchaseOutcome {
        if let product = groupProducts[planID] {
            return try await purchase(product)
        }
        guard let product = paywall?.products.first(where: { $0.productId == planID }) else {
            throw .purchaseFailed
        }
        let result = await Apphud.purchase(product)
        await refresh()
        if result.userCanceled { return .cancelled }
        if result.isPending { return .pending }
        guard result.error == nil, result.success || isPremium else { throw .purchaseFailed }
        return .purchased
    }
    
    func restore() async throws(SubscriptionError) -> Bool {
        let result = await Apphud.restorePurchases()
        await refresh()
        if result?.error != nil, !isPremium { throw .restoreFailed }
        return isPremium
    }
    
    private func purchase(_ product: Product) async throws(SubscriptionError) -> PurchaseOutcome {
        let result = await Apphud.purchase(product)
        await refresh()
        if result.isPending { return .pending }
        if result.success || isPremium { return .purchased }
        if result.error == nil || (result.error as? SKError)?.code == .paymentCancelled { return .cancelled }
        throw .purchaseFailed
    }
    
    private func productsFromPermissionGroups() async -> [Product] {
        let available = Set((await Apphud.permissionGroups() ?? []).flatMap(\.productIds))
        let ids = Self.paywallProductIDs.filter(available.contains)
        guard !ids.isEmpty, let products = try? await Product.products(for: ids) else { return [] }
        return ids.compactMap { id in products.first { $0.id == id } }
    }
    
    private func refresh() async {
        var hasAccess = Apphud.hasPremiumAccess()
        if !hasAccess {
            for await result in Transaction.currentEntitlements {
                if case let .verified(transaction) = result, transaction.revocationDate == nil {
                    hasAccess = true
                    break
                }
            }
        }
        premium.set(hasAccess)
    }
    
    private static func weeks(in period: Product.SubscriptionPeriod) -> Decimal? {
        let value = Decimal(period.value)
        switch period.unit {
            case .day: return value / 7
            case .week: return value
            case .month: return value * 52 / 12
            case .year: return value * 52
            @unknown default: return nil
        }
    }
    
    private static func plan(from product: Product) -> SubscriptionPlan {
        let period = product.subscription?.subscriptionPeriod
        let weekly = period.flatMap(weeks(in:)).map { product.price / $0 }
        return SubscriptionPlan(
            id: product.id,
            period: period.map(Self.period(from:)) ?? .other,
            price: product.price,
            displayPrice: product.displayPrice,
            weeklyPrice: weekly,
            weeklyDisplayPrice: weekly.map { product.priceFormatStyle.format($0) }
        )
    }
    
    private static func period(from period: Product.SubscriptionPeriod) -> SubscriptionPlan.Period {
        switch (period.unit, period.value) {
            case (.week, 1), (.day, 7): .week
            case (.month, 1): .month
            case (.year, 1): .year
            default: .other
        }
    }
}
