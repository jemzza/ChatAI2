import SwiftUI

struct NavigationHeader<Trailing: View>: View {
    let title: Text?
    let onBack: () -> Void
    @ViewBuilder let trailing: () -> Trailing
    
    init(
        _ title: LocalizedStringKey? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title.map { Text($0) }
        self.onBack = onBack
        self.trailing = trailing
    }
    
    init(
        title: Text?,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing
    }
    
    var body: some View {
        ZStack {
            if let title {
                title
                    .font(AppFont.navigationTitle)
                    .foregroundStyle(Color.appAccent)
                    .lineLimit(1)
                    .padding(.horizontal, 56)
            }
            HStack {
                BackButton(action: onBack)
                Spacer()
                trailing()
            }
        }
        .frame(height: AppMetrics.rowHeight)
        .padding(.horizontal, AppMetrics.sideInset)
        .padding(.vertical, 4)
    }
}

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image("IconBack")
                .renderingMode(.template)
                .foregroundStyle(Color.appAccent)
                .frame(width: 44, height: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("Back"))
    }
}
