//
//  DependencyPlan.swift
//  AIChat2
//

import Foundation

struct DependencyPlan: Hashable, Sendable {
    enum Storage: Hashable, Sendable {
        case disk
        case previewData
    }
    
    enum Subscription: Hashable, Sendable {
        case apphud
        case fake(isPremium: Bool)
    }
    
    let subscription: Subscription
    
    init(subscription: Subscription = .apphud) {
        self.subscription = subscription
    }
    
    init(options: LaunchOptions) {
        subscription = options.mockPremium.map { .fake(isPremium: $0) } ?? .apphud
    }
}
