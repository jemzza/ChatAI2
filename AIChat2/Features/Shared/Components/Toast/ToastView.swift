import SwiftUI

struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 24, height: 24)
            Text(message.text)
                .font(AppFont.headline)
                .foregroundStyle(Color.appAccent)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: AppMetrics.cardRadius).strokeBorder(Color.appSeparator))
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var icon: some View {
        switch message.kind {
            case .success:
                Image("IconCheck")
            case .failure:
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.red)
        }
    }
}

extension View {
    func toast(_ message: Binding<ToastMessage?>, duration: Duration = .seconds(2)) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView(message: ToastMessage(kind: .success, text: "Copied"))
        ToastView(message: ToastMessage(kind: .failure, text: "Copy failed"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}
