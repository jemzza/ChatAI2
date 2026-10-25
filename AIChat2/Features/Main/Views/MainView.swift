import SwiftUI

struct MainView: View {
    @StateObject private var model: MainViewModel
    @EnvironmentObject private var router: AppRouter
    
    init(subscription: any SubscribableService) {
        _model = StateObject(wrappedValue: MainViewModel(subscription: subscription))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 40) {
                        VStack(spacing: 24) {
                            Image("IconSparklesLarge")
                                .frame(width: 60, height: 60)
                                .accessibilityHidden(true)
                            Text("Your AI tools,\nready to go")
                                .font(AppFont.title)
                                .tracking(0.4)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.appAccent)
                            askField
                        }
                        VideoGeneratorCard { router.push(.templates) }
                    }
                    .padding(.horizontal, AppMetrics.sideInset)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                }
                .scrollBounceBehaviorIfAvailable()
            }
        }
        .background(GlowBackgroundView())
        .task { await model.observeSubscription() }
    }
    
    private var header: some View {
        HStack {
            CircleIconButton(label: "History") {
                router.push(.history(.chat))
            } icon: {
                HistoryIcon()
            }
            Spacer()
            if model.showsProButton {
                ProButton { router.showPaywall(from: .proButton) }
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            CircleIconButton(label: "Settings") {
                router.push(.settings)
            } icon: {
                Image("IconSettings")
                    .renderingMode(.template)
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .padding(.vertical, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.showsProButton)
    }
    
    private var askField: some View {
        Button {
            router.push(.chat(chatId: nil))
        } label: {
            HStack(spacing: 16) {
                Image("IconSparkles")
                    .frame(width: 24, height: 24)
                Text("Ask anything...")
                    .font(AppFont.body)
                    .foregroundStyle(Color.appAccent.opacity(0.5))
                Spacer()
            }
            .padding(16)
            .background(Color.appSurface.opacity(0.7), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cardRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.appGradientStart.opacity(0.6), .appGradientEnd.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct HistoryIcon: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("IconHistoryCircle")
                .renderingMode(.template)
                .offset(x: 1.25, y: 1.25)
            Image("IconHistoryHands")
                .renderingMode(.template)
                .offset(x: 11.25, y: 7.25)
        }
        .foregroundStyle(Color.appAccent)
        .frame(width: 24, height: 24, alignment: .topLeading)
    }
}

private struct ProButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image("IconSparkleSmall")
                    .frame(width: 14, height: 14)
                Text("PRO")
                    .font(AppFont.subheadlineMedium.weight(.semibold))
                    .tracking(0.56)
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(AppGradient.primary, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MainView(subscription: FakeSubscriptionService(isPremium: false))
    }
    .environmentObject(AppRouter(settings: UserDefaultsSettingsStore()))
}
#endif
