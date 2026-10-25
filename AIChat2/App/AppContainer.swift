import Alamofire
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
        let chat = ChatService(
            repository: chats,
            provider: makeChatProvider(plan.model, subscription: subscription),
            connectivity: makeConnectivity(plan.network),
            backgroundTasks: UIKitBackgroundTasks()
        )
        
        return AppDependencies(subscription: subscription, chats: chats, chat: chat)
    }
    
    private func makeChatProvider(_ model: DependencyPlan.Model, subscription: any SubscribableService) -> any ChatProvider {
        switch model {
            case .live:
                return DolaChatProvider(client: networkClient(service: "dola", subscription: subscription))
            case let .demo(slow):
#if DEBUG
                return FakeChatProvider(delay: slow ? .seconds(3) : .seconds(1))
#else
                return DolaChatProvider(client: networkClient(service: "dola", subscription: subscription))
#endif
            case let .failing(kind):
#if DEBUG
                let retryAfter: Duration? = kind == .rateLimited ? .seconds(30) : nil
                return FakeChatProvider(script: .fail(APIError(kind: kind, retryAfter: retryAfter)), delay: .seconds(1))
#else
                return DolaChatProvider(client: networkClient(service: "dola", subscription: subscription))
#endif
        }
    }
    
    private func makeConnectivity(_ network: DependencyPlan.Network) -> any ConnectivityMonitoring {
        switch network {
            case .system:
                return NetworkConnectivityMonitor()
            case .offline:
#if DEBUG
                return FakeConnectivityMonitor(isOnline: false)
#else
                return NetworkConnectivityMonitor()
#endif
        }
    }
    
    private func networkClient(service: String, subscription: any SubscribableService) -> any NetworkClient {
        let interceptor = NebulaIntercepter(
            token: Secrets.nebulaAPIToken,
            appID: Self.apiAppID,
            userID: { await subscription.userID }
        )
        return AFNetworkClient(
            baseURL: Self.apiBaseURL.appendingPathComponent(service),
            session: Session(interceptor: interceptor)
        )
    }
    
    private static let apiAppID = "com.test.test"
    private static let apiBaseURL = URL(string: "https://nebulaapps.site")!
    
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
