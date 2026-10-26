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
    let isActive: Bool
    let onSelect: (VideoTemplate) -> Void
    
    @StateObject private var playback: PreviewPlaybackController
    
    init(
        templates: [VideoTemplate],
        columns: [GridItem],
        thumbnails: any VideoThumbnailing,
        pool: PreviewPlayerPool,
        isActive: Bool,
        onSelect: @escaping (VideoTemplate) -> Void
    ) {
        self.templates = templates
        self.columns = columns
        self.thumbnails = thumbnails
        self.isActive = isActive
        self.onSelect = onSelect
        _playback = StateObject(wrappedValue: PreviewPlaybackController(pool: pool))
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(templates) { template in
                    TemplateCard(template: template, thumbnails: thumbnails, player: playback.player(for: template.id)) {
                        onSelect(template)
                    }
                    .previewFrame(id: template.id)
                }
            }
            .padding(.horizontal, AppMetrics.sideInset)
            .padding(.bottom, 16)
        }
        .previewPlayback(playback)
        .onAppear {
            let urls = Dictionary(templates.compactMap { template in template.previewURL.map { (template.id, $0) } }) { first, _ in first }
            playback.url = { id in (id.base as? Int64).flatMap { urls[$0] } }
            playback.isActive = isActive
        }
        .onChange(of: isActive) { playback.isActive = $0 }
    }
}

struct TemplateCard: View {
    let template: VideoTemplate
    let thumbnails: any VideoThumbnailing
    var player: AVPlayer?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VideoThumbnailView(url: template.previewURL, thumbnails: thumbnails)
                .overlay { PreviewVideoLayer(player: player) }
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
    }
}
