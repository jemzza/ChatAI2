import Foundation

enum AlertPurchase: Identifiable, Equatable {
    case purchaseFailed
    case purchasePending
    case restoreFailed
    case nothingToRestore
    
    var id: Self { self }
}
