//
//  SubscrubableService.swift
//  AIChat2
//

@MainActor
protocol SubscribableService: AnyObject, Sendable {
    
    var isPremium: Bool { get }
    var userID: String { get }
    
    func premiumUpdates() -> AsyncStream<Bool>
    func paywallPlans() async throws(SubscriptionError) -> [SubscriptionPlan]
    func paywallShown()
    func purchase(planID: SubscriptionPlan.ID) async throws(SubscriptionError) -> PurchaseOutcome
    func restore() async throws(SubscriptionError) -> Bool
}
