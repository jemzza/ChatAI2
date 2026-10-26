import SwiftUI

struct SegmentedTabs: View {
    @Binding var selection: HistoryTab
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 0) {
            segment(.chat, title: "Chat")
            segment(.video, title: "Video")
        }
        .padding(4)
        .frame(height: 40)
        .background(Color.appSurface.opacity(0.4), in: Capsule())
    }
    
    private func segment(_ tab: HistoryTab, title: LocalizedStringKey) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selection = tab }
        } label: {
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if selection == tab {
                        Capsule()
                            .fill(Color.appFillTertiary)
                            .matchedGeometryEffect(id: "segment", in: namespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }
}

struct SectionTitle: View {
    let text: Text
    
    var body: some View {
        text
            .font(AppFont.title3)
            .foregroundStyle(Color.appAccent)
            .textCase(nil)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppMetrics.sideInset)
            .listRowInsets(EdgeInsets())
            .accessibilityAddTraits(.isHeader)
    }
}

struct ChatHistoryRow: View {
    let summary: ChatSummary
    
    var body: some View {
        HStack(spacing: 16) {
            Image("IconGenerate")
                .resizable()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.chat.title)
                    .font(AppFont.headline)
                    .foregroundStyle(Color.appAccent)
                if let last = summary.lastMessage {
                    Text(MarkdownParser.plainText(last))
                        .font(AppFont.subheadline)
                        .foregroundStyle(Color.appAccent.opacity(0.5))
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if summary.chat.pinnedAt != nil {
                Image(systemName: "pin")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appAccent.opacity(0.3))
                    .accessibilityLabel(Text("Pinned"))
            }
        }
        .padding(16)
        .background(Color.appSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
    }
}

struct FolderRow: View {
    let folder: Folder
    let count: Int
    let isExpanded: Bool
    let toggle: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 16) {
                Image(systemName: "folder")
                    .font(.system(size: 20))
                    .foregroundStyle(AppGradient.primary)
                    .frame(width: 28, height: 28)
                Text(folder.name)
                    .font(AppFont.headline)
                    .foregroundStyle(Color.appAccent)
                    .lineLimit(1)
                Spacer()
                Text("\(count)")
                    .font(AppFont.subheadline)
                    .foregroundStyle(Color.appAccent.opacity(0.5))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appAccent.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(16)
            .background(Color.appSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityValue(Text(isExpanded ? "Expanded" : "Collapsed"))
    }
}

struct HistoryRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: 6, leading: AppMetrics.sideInset, bottom: 6, trailing: AppMetrics.sideInset))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

struct EmptyHistoryView: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 16) {
            Image(icon)
                .resizable()
                .frame(width: 60, height: 60)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFont.title)
                    .tracking(0.4)
                Text(subtitle)
                    .font(AppFont.body)
                    .opacity(0.5)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Color.appAccent)
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -40)
    }
}
