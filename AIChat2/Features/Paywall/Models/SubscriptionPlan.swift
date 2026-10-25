import Foundation

struct SubscriptionPlan: Identifiable, Hashable, Sendable {
    enum Period: Hashable, Sendable {
        case week
        case month
        case year
        case other
    }
    
    let id: String
    let period: Period
    let price: Decimal
    let displayPrice: String
    let weeklyPrice: Decimal?
    let weeklyDisplayPrice: String?
}

enum PurchaseOutcome: Hashable, Sendable {
    case purchased
    case cancelled
    case pending
}

enum SubscriptionError: Error, Hashable, Sendable {
    case productsUnavailable
    case purchaseFailed
    case restoreFailed
}
