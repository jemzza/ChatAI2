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
                    NavigationStack(path: $router.path) {
                        MainView(subscription: dependencies.subscription)
                            .navigationDestination(for: AppRoute.self) { route in
                                destination(route)
                                    .toolbar(.hidden, for: .navigationBar)
                            }
                            .toolbar(.hidden, for: .navigationBar)
                    }
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
    
    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
            case let .chat(chatId):
                ChatView(chatId: chatId, dependencies: dependencies)
            case .templates:
                TemplatesView(dependencies: dependencies)
            case let .templatePreview(templateId, category):
                TemplatePreviewView(templateId: templateId, category: category, dependencies: dependencies)
            case let .generation(id):
                GenerationView(id: id, dependencies: dependencies)
            case let .history(tab):
                HistoryView(tab: tab, dependencies: dependencies)
            case .settings:
                UnderConstructionView()
        }
    }
}

private struct UnderConstructionView: View {
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader { router.pop() }
            Spacer()
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}
