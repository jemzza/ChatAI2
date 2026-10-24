//
//  RootView.swift
//  AIChat2
//

import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies
    @StateObject private var router: AppRouter
    
    init(dependencies: AppDependencies, settings: any SettingsStorable) {
        self.dependencies = dependencies
        _router = StateObject(wrappedValue: AppRouter(settings: settings))
    }
    
    var body: some View {
        ZStack {
            switch router.stage {
                case .onboarding:
                    OnboardingView { router.finishOnboarding() }
                        .transition(.opacity)
                case .main:
                    EmptyView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: router.stage)
        .fullScreenCover(item: $router.paywall) { _ in
            PaywallView(subscription: dependencies.subscription) {
                router.dismissPaywall()
            }
        }
        .environmentObject(router)
    }
}
