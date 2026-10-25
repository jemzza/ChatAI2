import Foundation

struct DependencyPlan: Hashable, Sendable {
    enum Storage: Hashable, Sendable {
        case disk
        case previewData
    }
    
    enum Network: Hashable, Sendable {
        case system
        case offline
    }
    
    enum Model: Hashable, Sendable {
        case live
        case demo(slow: Bool)
        case failing(ErrorKind)
    }
    
    enum Subscription: Hashable, Sendable {
        case apphud
        case fake(isPremium: Bool)
    }
    
    let storage: Storage
    let network: Network
    let model: Model
    let subscription: Subscription
    
    init(
        storage: Storage = .disk,
        network: Network = .system,
        model: Model = .live,
        subscription: Subscription = .apphud
    ) {
        self.storage = storage
        self.network = network
        self.model = model
        self.subscription = subscription
    }
    
    init(options: LaunchOptions) {
        storage = options.useMockData ? .previewData : .disk
        network = options.forceOffline || options.mockError == .offline ? .offline : .system
        if let kind = options.mockError, kind != .offline {
            model = .failing(kind)
        } else if options.useMockData || options.slowReply {
            model = .demo(slow: options.slowReply)
        } else {
            model = .live
        }
        subscription = options.mockPremium.map { .fake(isPremium: $0) } ?? .apphud
    }
}
