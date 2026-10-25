import SwiftUI

struct ChipButton: View {
    enum Style {
        case filled
        case suggestion
    }
    
    let title: String
    var isSelected = false
    var style = Style.filled
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(AppFont.subheadline)
                .foregroundStyle(Color.appAccent.opacity(textOpacity))
                .lineLimit(1)
                .padding(.horizontal, style == .suggestion ? 14 : 16)
                .padding(.vertical, style == .suggestion ? 10 : 8)
                .frame(minWidth: style == .filled ? 76 : nil)
                .background(background)
                .overlay {
                    if style == .suggestion {
                        Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var textOpacity: Double {
        switch style {
            case .suggestion: 0.9
            case .filled: isSelected ? 1 : 0.5
        }
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
            case .suggestion:
                Capsule().fill(Color.appSurface.opacity(0.8))
            case .filled:
                if isSelected {
                    Capsule().fill(AppGradient.primary)
                } else {
                    Capsule().fill(Color.appSurface.opacity(0.6))
                }
        }
    }
}
