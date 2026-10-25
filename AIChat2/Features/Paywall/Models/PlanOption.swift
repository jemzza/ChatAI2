import Foundation

struct PlanOption: Identifiable, Equatable {
    let id: SubscriptionPlan.ID
    let period: SubscriptionPlan.Period
    let weeklyPrice: String?
    let totalPrice: String
    let savingsPercent: Int?
    }
