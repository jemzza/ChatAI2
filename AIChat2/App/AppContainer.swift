//
//  AppContainer.swift
//  AIChat2
//

import Foundation

@MainActor
final class AppContainer {
    enum Environment: Sendable, Equatable {
        case live
        case unitTests
    }
    
    let environment: Environment
    let launchOptions: LaunchOptions
    let settings: any SettingsStorable
    
    init(
        environment: Environment,
        launchOptions: LaunchOptions? = nil,
        settings: (any SettingsStorable)? = nil
    ) {
        self.environment = environment
        self.launchOptions = launchOptions ?? .none
        self.settings = settings ?? UserDefaultsSettingsStore()
        if self.launchOptions.resetOnboarding { self.settings.hasCompletedOnboarding = false }
        if self.launchOptions.skipOnboarding { self.settings.hasCompletedOnboarding = true }
    }
    
    static func environment(for processInfo: ProcessInfo) -> Environment {
        processInfo.environment["XCTestConfigurationFilePath"] == nil ? .live : .unitTests
    }
}

extension AppContainer {
    
    func makeDependencies() async throws -> AppDependencies {
        let plan = DependencyPlan(options: launchOptions)
        let subscription = makeSubscription(plan.subscription)
        let database = try plan.storage == .previewData ? AppDatabase.inMemory() : AppDatabase.onDisk()
        let chats = GRDBChatRepository(database: database)
        try await chats.markGeneratingAsInterrupted()
        
        return AppDependencies(subscription: subscription, chats: chats)
    }
    
    private func makeSubscription(_ subscription: DependencyPlan.Subscription) -> any SubscribableService {
        switch subscription {
            case .apphud:
                return ApphudSubscriptionService(apiKey: Secrets.apphudAPIKey)
            case let .fake(isPremium):
#if DEBUG
                return FakeSubscriptionService(isPremium: isPremium)
#else
                return ApphudSubscriptionService(apiKey: Secrets.apphudAPIKey)
#endif
        }
    }
}
