import SwiftUI

struct LoadErrorView: View {
    let kind: ErrorKind
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: kind == .offline ? "wifi.slash" : "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(AppGradient.primary)
            Text(ErrorText.key(for: kind))
                .font(AppFont.body)
                .foregroundStyle(Color.appAccent.opacity(0.8))
                .multilineTextAlignment(.center)
            GradientButton(title: "Try again", action: onRetry)
                .frame(width: 200)
        }
        .padding(AppMetrics.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
