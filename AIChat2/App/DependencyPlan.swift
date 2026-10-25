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
    
    let storage: Storage
    let subscription: Subscription
    
    init(storage: Storage = .disk, subscription: Subscription = .apphud) {
        self.storage = storage
        self.subscription = subscription
    }
    
    init(options: LaunchOptions) {
        storage = options.useMockData ? .previewData : .disk
        subscription = options.mockPremium.map { .fake(isPremium: $0) } ?? .apphud
    }
}
