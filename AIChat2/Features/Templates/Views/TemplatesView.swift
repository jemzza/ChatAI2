import AVFoundation
import SwiftUI

struct TemplatesView: View {
    @StateObject private var model: TemplatesViewModel
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase
    @State private var pool = PreviewPlayerPool()
    @State private var isOnScreen = false
    private let thumbnails: any VideoThumbnailing
    
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
    init(dependencies: AppDependencies) {
        _model = StateObject(wrappedValue: TemplatesViewModel(api: dependencies.videoAPI))
        thumbnails = dependencies.thumbnails
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AvatarHeader(icon: "IconImageToImageWhite", title: "AI Video") { router.pop() }
            content
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await model.load() }
        .onAppear { isOnScreen = true }
        .onDisappear {
            isOnScreen = false
            pool.stopAll()
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { pool.stopAll() }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch model.state {
            case .loading:
                VStack(spacing: 24) {
                    categoriesPlaceholder
                    placeholderGrid
                }
                .padding(.top, 24)
            case let .failed(kind):
                LoadErrorView(kind: kind) { Task { await model.load() } }
            case .loaded:
                VStack(spacing: 24) {
                    categoriesRow
                    TabView(selection: $model.selectedCategory) {
                        ForEach(model.categories) { category in
                            TemplatesGrid(
                                templates: model.templates(in: category),
                                columns: columns,
                                thumbnails: thumbnails,
                                pool: pool,
                                isActive: isOnScreen && scenePhase == .active && category == model.selectedCategory
                            ) { template in
                                router.push(.templatePreview(templateId: template.id, category: category.id))
                            }
                            .tag(Optional(category))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .padding(.top, 24)
        }
    }
    
    private var categoriesRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.categories) { category in
                        ChipButton(title: category.title, isSelected: category == model.selectedCategory) {
                            select(category)
                        }
                        .id(category.id)
                    }
                }
                .padding(.horizontal, AppMetrics.sideInset)
            }
            .onChange(of: model.selectedCategory) { category in
                withAnimation { proxy.scrollTo(category?.id, anchor: .center) }
            }
        }
    }
    
    private func select(_ category: TemplatesViewModel.Category) {
        let categories = model.categories
        var isNeighbor = false
        if let target = categories.firstIndex(of: category),
           let current = model.selectedCategory.flatMap(categories.firstIndex(of:)) {
            isNeighbor = abs(target - current) == 1
        }
        withAnimation(isNeighbor ? .easeInOut(duration: 0.3) : nil) {
            model.selectedCategory = category
        }
    }
    
    private var categoriesPlaceholder: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                Capsule()
                    .fill(Color.appSurface.opacity(0.6))
                    .frame(width: 76, height: 33)
                    .shimmer()
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, AppMetrics.sideInset)
    }
    
    private var placeholderGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppMetrics.cardRadius)
                    .fill(Color.appSurface)
                    .frame(height: 232)
                    .shimmer()
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            }
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct TemplatesGrid: View {
    let templates: [VideoTemplate]
    let columns: [GridItem]
    let thumbnails: any VideoThumbnailing
    let pool: PreviewPlayerPool
    let isActive: Bool
    let onSelect: (VideoTemplate) -> Void
    
    @State private var tracker = VisibilityTracker()
    @State private var playingIDs: Set<Int64> = []
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(templates) { template in
                        TemplateCard(
                            template: template,
                            thumbnails: thumbnails,
                            player: playingIDs.contains(template.id) ? pool.player(for: template.id) : nil
                        ) { onSelect(template) }
                        .background {
                            GeometryReader { card in
                                Color.clear.preference(
                                    key: CardFramesKey.self,
                                    value: [template.id: card.frame(in: .named(VisibilityTracker.space))]
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, AppMetrics.sideInset)
                .padding(.bottom, 16)
            }
            .coordinateSpace(name: VisibilityTracker.space)
            .onPreferenceChange(CardFramesKey.self) { frames in
                tracker.frames = frames
                tracker.viewport = CGRect(origin: .zero, size: proxy.size)
                scheduleUpdate()
            }
        }
        .onAppear(perform: scheduleUpdate)
        .onChange(of: isActive) { _ in scheduleUpdate() }
        .onDisappear { tracker.settleTask?.cancel() }
    }
    
    private func scheduleUpdate() {
        tracker.settleTask?.cancel()
        guard isActive, !ProcessInfo.processInfo.isLowPowerModeEnabled else {
            if !playingIDs.isEmpty { playingIDs = [] }
            return
        }
        tracker.settleTask = Task {
            guard (try? await Task.sleep(for: .milliseconds(300))) != nil else { return }
            let requests = visibleRequests()
            pool.play(requests)
            let ids = Set(requests.prefix(pool.capacity).map(\.id))
            if ids != playingIDs { playingIDs = ids }
        }
    }
    
    private func visibleRequests() -> [PreviewPlayerPool.Request] {
        let urls = Dictionary(templates.compactMap { template in template.previewURL.map { (template.id, $0) } }) { first, _ in first }
        return tracker.frames
            .filter { _, frame in
                let visible = frame.intersection(tracker.viewport)
                return !visible.isNull && visible.height * visible.width >= frame.height * frame.width * 0.6
            }
            .sorted { lhs, rhs in
                lhs.value.minY == rhs.value.minY ? lhs.value.minX < rhs.value.minX : lhs.value.minY < rhs.value.minY
            }
            .compactMap { id, _ in urls[id].map { PreviewPlayerPool.Request(id: id, url: $0) } }
    }
}

private final class VisibilityTracker {
    static let space = "templatesGrid"
    var frames: [Int64: CGRect] = [:]
    var viewport: CGRect = .zero
    var settleTask: Task<Void, Never>?
}

private struct CardFramesKey: PreferenceKey {
    static let defaultValue: [Int64: CGRect] = [:]
    
    static func reduce(value: inout [Int64: CGRect], nextValue: () -> [Int64: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct TemplateCard: View {
    let template: VideoTemplate
    let thumbnails: any VideoThumbnailing
    var player: AVPlayer?
    let action: () -> Void
    
    @State private var isVideoReady = false
    
    var body: some View {
        Button(action: action) {
            VideoThumbnailView(url: template.previewURL, thumbnails: thumbnails)
                .overlay {
                    if let player {
                        PlayerLayerView(player: player) { isVideoReady = $0 }
                            .opacity(isVideoReady ? 1 : 0)
                            .animation(.easeOut(duration: 0.25), value: isVideoReady)
                    }
                }
                .frame(height: 232)
                .frame(maxWidth: .infinity)
                .overlay {
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0), Color.appSurface.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottom) {
                    Text(template.name)
                        .font(AppFont.body)
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .padding(8)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .onChange(of: player == nil) { isEmpty in
            if isEmpty { isVideoReady = false }
        }
    }
}
