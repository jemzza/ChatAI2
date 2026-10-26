import SwiftUI

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(Shimmer(isActive: isActive))
    }
}

private struct Shimmer: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                ShimmerHighlight()
                    .transition(.opacity)
            }
        }
    }
}

private struct ShimmerHighlight: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * 0.6
            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.08), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width)
            .offset(x: -width + phase * (proxy.size.width + width))
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1 }
        }
    }
}
