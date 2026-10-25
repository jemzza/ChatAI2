import SwiftUI

struct OptionRow: View {
    let title: LocalizedStringKey
    let value: Text
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).opacity(0.6)
                Spacer()
                value
            }
            .font(AppFont.bodyBold)
            .foregroundStyle(Color.appAccent)
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(Color.appSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct DropdownAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct DropdownMenu<Option: Hashable, Label: View>: View {
    let options: [Option]
    let selection: Option
    @ViewBuilder let label: (Option) -> Label
    let onSelect: (Option) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { offset, option in
                Button {
                    onSelect(option)
                } label: {
                    HStack(spacing: 12) {
                        label(option)
                        Spacer(minLength: 0)
                        if option == selection {
                            Image("IconCheckGradient")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(option == selection ? Color.white.opacity(0.06) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
                if offset < options.count - 1 {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
            }
        }
        .frame(width: 220)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomTrailing)))
    }
}

struct DropdownOptionText: View {
    let title: Text
    let subtitle: LocalizedStringKey
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            title
                .font(AppFont.bodyMedium)
                .foregroundStyle(Color.appAccent.opacity(isSelected ? 1 : 0.85))
            Text(subtitle)
                .font(AppFont.caption)
                .foregroundStyle(Color.appAccent.opacity(0.45))
        }
    }
}

struct AspectIcon: View {
    let aspect: VideoAspect
    let isSelected: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .strokeBorder(Color.white.opacity(isSelected ? 1 : 0.6), lineWidth: 1.5)
            .frame(width: size.width, height: size.height)
            .frame(width: 22, height: 22)
    }
    
    private var size: CGSize {
        switch aspect {
            case .landscape: CGSize(width: 18, height: 10)
            case .portrait: CGSize(width: 10, height: 18)
            case .square: CGSize(width: 18, height: 18)
        }
    }
}
