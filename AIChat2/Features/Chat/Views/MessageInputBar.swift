import SwiftUI
import UIKit

struct MessageInputBar: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey
    var isSendEnabled: Bool
    var focus: FocusState<Bool>.Binding
    let onSend: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(AppFont.body)
                .foregroundStyle(Color.appAccent)
                .tint(.appGradientEnd)
                .lineLimit(1...3)
                .focused(focus)
                .padding(.vertical, 10)
            Button(action: onSend) {
                Image("IconSend")
                    .renderingMode(.template)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 40, height: 40)
                    .background(AppGradient.primary, in: Circle())
                    .opacity(isSendEnabled ? 1 : 0.3)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!isSendEnabled)
            .accessibilityLabel(Text("Send"))
            .animation(.easeInOut(duration: 0.2), value: isSendEnabled)
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .padding(.vertical, 14)
        .background(
            TopRoundedRectangle(radius: AppMetrics.cardRadius)
                .fill(Color.appSurface)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct TopRoundedRectangle: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
