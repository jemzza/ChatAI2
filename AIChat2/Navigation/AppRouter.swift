//
//  Router.swift
//  AIChat2
//

import Foundation
import Combine

enum AppRoute: Hashable {

}

enum HistoryTab: Hashable, CaseIterable {
    case chat
    case video
}

/// Откуда открыли пейвол — для аналитики и поведения после закрытия.
enum PaywallSource: Hashable {
    case onboarding
    case proButton
    case settings
    /// Попытка премиум-действия (отправка в чате, «Create» видео).
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
    
    /// Конец онбординга: дальше — главный экран, поверх него пейвол (заметки к макету).
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
    
    /// Заменяет верхний экран
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
    
    /// Премиум-действие: есть подписка — `true`; нет — открывает пейвол и возвращает `false`.
    func requirePremium(_ subscription: any SubscribableService) -> Bool {
        if subscription.isPremium { return true }
        showPaywall(from: .premiumAction)
        return false
    }
}
