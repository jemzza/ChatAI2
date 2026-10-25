import Foundation
import Combine

enum AppRoute: Hashable {
    case chat(chatId: UUID?)
    case templates
    case templatePreview(templateId: Int64, category: String?)
    case generation(id: UUID)
    case history(HistoryTab)
    case settings
}

enum HistoryTab: Hashable, CaseIterable {
    case chat
    case video
}

enum PaywallSource: Hashable {
    case onboarding
    case proButton
    case settings
    case premiumAction
}

struct PaywallRequest: Identifiable, Hashable {
    let id = UUID()
    let source: PaywallSource
}

@MainActor
final class AppRouter: ObservableObject {
    enum Stage: Hashable {
        case onboarding
        case main
    }
    
    @Published private(set) var stage: Stage
    @Published var path: [AppRoute] = []
    @Published var paywall: PaywallRequest?
    
    private let settings: any SettingsStorable
    
    init(settings: any SettingsStorable) {
        self.settings = settings
        stage = settings.hasCompletedOnboarding ? .main : .onboarding
    }
    
    func finishOnboarding() {
        settings.hasCompletedOnboarding = true
        stage = .main
        paywall = PaywallRequest(source: .onboarding)
    }
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func replaceTop(with route: AppRoute) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }
    
    func showPaywall(from source: PaywallSource) {
        guard paywall == nil else { return }
        paywall = PaywallRequest(source: source)
    }
    
    func dismissPaywall() {
        paywall = nil
    }
    
    func requirePremium(_ subscription: any SubscribableService) -> Bool {
        if subscription.isPremium { return true }
        showPaywall(from: .premiumAction)
        return false
    }
}
