import SwiftUI

struct SettingsRow: View {
    enum Accessory {
        case chevron(detail: String? = nil)
        case toggle(Binding<Bool>)
    }
    
    let systemImage: String
    let title: LocalizedStringKey
    var accessory = Accessory.chevron()
    var action: () -> Void = {}
    
    var body: some View {
        switch accessory {
            case .chevron:
                Button(action: action) { label }
                    .buttonStyle(PressableButtonStyle())
            case .toggle:
                label
        }
    }
    
    var label: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .foregroundStyle(AppGradient.primary)
                .frame(width: 28)
                .padding(.trailing, 8)
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .frame(height: AppMetrics.rowHeight)
        .background(Color.appSurface.opacity(0.4), in: Capsule())
        .contentShape(Capsule())
    }
    
    @ViewBuilder
    private var trailing: some View {
        switch accessory {
            case let .chevron(detail):
                HStack(spacing: 16) {
                    if let detail {
                        Text(detail)
                            .font(.system(size: 17))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppGradient.primary)
                }
            case let .toggle(isOn):
                Toggle(isOn: isOn) { EmptyView() }
                    .labelsHidden()
                    .tint(.appGradientEnd)
        }
    }
}

struct SettingsGroup<Rows: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let rows: () -> Rows
    
    var body: some View {
        VStack(spacing: AppMetrics.cellSpacing) {
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(Color.appAccent.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppMetrics.sideInset)
                .padding(.bottom, 6)
                .accessibilityAddTraits(.isHeader)
            rows()
                .padding(.horizontal, AppMetrics.sideInset)
        }
    }
}
