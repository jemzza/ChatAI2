import SwiftUI

struct OnboardingView: View {
    
    let completion: () -> Void
    @State private var selection = 0
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                ForEach(Page.pages) { page in
                    pageView(page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                PageIndicatorView(count: Page.pages.count, selection: selection)
                GradientButton(title: "Continue", action: next)
                    .padding(.horizontal, AppMetrics.sideInset)
            }
            .padding(.bottom, 8)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
    
    private func pageView(_ page: Page) -> some View {
        VStack(spacing: 12) {
            Text(page.title)
                .font(AppFont.title)
                .foregroundStyle(Color.appAccent)
            Text(page.subtitle)
                .font(AppFont.body)
                .foregroundStyle(Color.appLabelTertiary)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, AppMetrics.sideInset)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Image(page.image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }
    
    private func next() {
        if selection < Page.pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) { selection += 1 }
        } else {
            completion()
        }
    }
}

#Preview {
    OnboardingView() {}
}
