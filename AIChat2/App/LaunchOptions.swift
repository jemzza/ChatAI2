//
//  LaunchOptions.swift
//  AIChat2
//

import Foundation

struct LaunchOptions: Hashable, Sendable {
    var useMockData = false
    var forceOffline = false
    var mockError: ErrorKind?
    var slowReply = false
    var mockPremium: Bool?
    var showComponentGallery = false
    var resetOnboarding = false
    var skipOnboarding = false
    
    static let none = LaunchOptions()
    
    var usesMocks: Bool { self != .none }
    
    init() {}
    
    init(arguments: [String]) {
#if DEBUG
        useMockData = arguments.contains("-mockData")
        forceOffline = arguments.contains("-mockOffline")
        slowReply = arguments.contains("-mockSlowReply")
        showComponentGallery = arguments.contains("-componentGallery")
        resetOnboarding = arguments.contains("-resetOnboarding")
        skipOnboarding = arguments.contains("-skipOnboarding")
        if arguments.contains("-mockPremium") {
            mockPremium = true
        } else if arguments.contains("-mockFree") {
            mockPremium = false
        }
        if let index = arguments.firstIndex(of: "-mockError") {
            let value = arguments.index(after: index) < arguments.endIndex ? arguments[index + 1] : ""
            mockError = Self.errorKind(for: value)
        }
#endif
    }
    
    private static func errorKind(for value: String) -> ErrorKind {
        switch value {
            case "429": .rateLimited
            case "401": .unauthorized
            case "402": .paymentRequired
            case "403": .forbidden
            case "500": .server
            case "offline": .offline
            default: .unknown
        }
    }
}
