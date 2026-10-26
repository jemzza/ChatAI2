import SwiftUI

struct HistoryView: View {
    @StateObject private var model: HistoryViewModel
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var playback = PreviewPlaybackController()
    @State private var isOnScreen = false
    private let thumbnails: any VideoThumbnailing
    private let media: any MediaStoring
    
    @State private var renaming: ChatSummary?
    @State private var newTitle = ""
    @State private var deleting: ChatSummary?
    @State private var moving: ChatSummary?
    @State private var collapsedFolders: Set<UUID> = []
    @State private var isCreatingFolder = false
    @State private var chatForNewFolder: ChatSummary?
    @State private var renamingFolder: Folder?
    @State private var deletingFolder: Folder?
    @State private var folderName = ""
    
    init(tab: HistoryTab, dependencies: AppDependencies) {
        thumbnails = dependencies.thumbnails
        media = dependencies.media
        _model = StateObject(wrappedValue: HistoryViewModel(
            tab: tab,
            chats: dependencies.chats,
            chatService: dependencies.chat,
            videoRepository: dependencies.videos,
            videoService: dependencies.video
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader("History") { router.pop() }
            SegmentedTabs(selection: $model.tab)
                .padding(.horizontal, AppMetrics.sideInset)
                .padding(.vertical, 8)
            Group {
                switch model.tab {
                    case .chat: chats
                    case .video: videos
                }
            }
            .frame(maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: model.tab)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await model.observe() }
        .onAppear {
            isOnScreen = true
            playback.url = { [model, media] id in
                guard let id = id.base as? UUID,
                      let generation = model.videos.first(where: { $0.id == id }),
                      generation.status == .succeeded
                else { return nil }
                return generation.localVideoName.flatMap(media.localVideoURL(named:)) ?? generation.videoURL
            }
            playback.isActive = isPlaybackActive
        }
        .onDisappear {
            isOnScreen = false
            playback.stop()
        }
        .onChange(of: isPlaybackActive) { isActive in
            playback.isActive = isActive
            if !isActive { playback.stop() }
        }
        .alert("Rename chat", isPresented: isPresented($renaming)) {
            TextField("Chat name", text: $newTitle)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let chat = renaming { Task { await model.rename(chat.id, to: newTitle) } }
            }
            .disabled(!HistoryViewModel.isValidName(newTitle))
        } message: {
            Text("Enter a new name for this chat")
        }
        .alert("Delete chat?", isPresented: isPresented($deleting)) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let chat = deleting { Task { await model.delete(chat.id) } }
            }
        } message: {
            Text("This chat will be removed from your history.")
        }
        .alert("New folder", isPresented: $isCreatingFolder) {
            TextField("Folder name", text: $folderName)
            Button("Cancel", role: .cancel) { chatForNewFolder = nil }
            Button("Create") {
                let name = folderName
                let chat = chatForNewFolder
                chatForNewFolder = nil
                Task { await model.createFolder(named: name, moving: chat?.id) }
            }
            .disabled(!HistoryViewModel.isValidName(folderName))
        }
        .alert("Rename folder", isPresented: isPresented($renamingFolder)) {
            TextField("Folder name", text: $folderName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let folder = renamingFolder { Task { await model.renameFolder(folder.id, to: folderName) } }
            }
            .disabled(!HistoryViewModel.isValidName(folderName))
        }
        .alert("Delete folder?", isPresented: isPresented($deletingFolder)) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let folder = deletingFolder { Task { await model.deleteFolder(folder.id) } }
            }
        } message: {
            Text("Chats from this folder will stay in your history.")
        }
        .confirmationDialog(
            "Move to folder",
            isPresented: isPresented($moving),
            titleVisibility: .visible,
            presenting: moving
        ) { chat in
            ForEach(model.allFolders.filter { $0.id != chat.chat.folderId }) { folder in
                Button(folder.name) { Task { await model.move(chat.id, toFolder: folder.id) } }
            }
            if chat.chat.folderId != nil {
                Button("Remove from folder") { Task { await model.move(chat.id, toFolder: nil) } }
            }
            Button("New folder…") {
                chatForNewFolder = chat
                folderName = ""
                isCreatingFolder = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private var chats: some View {
        if model.isChatsEmpty {
            VStack(spacing: 0) {
                foldersHeader
                    .padding(.top, 22)
                EmptyHistoryView(
                    icon: "IconMagicPencil",
                    title: "No chats yet",
                    subtitle: "Start a conversation to see\nyour history here"
                )
            }
        } else {
            List {
                if !model.pinned.isEmpty {
                    chatSection(Text("Pinned"), chats: model.pinned)
                }
                foldersSection
                ForEach(model.sections) { section in
                    chatSection(title(for: section.group), chats: section.chats)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .animation(.easeInOut(duration: 0.25), value: model.sections)
            .animation(.easeInOut(duration: 0.25), value: model.pinned)
            .animation(.easeInOut(duration: 0.25), value: model.folders)
            .animation(.easeInOut(duration: 0.25), value: collapsedFolders)
        }
    }
    
    private var foldersSection: some View {
        Section {
            ForEach(model.folders) { section in
                let isExpanded = !collapsedFolders.contains(section.id)
                FolderRow(folder: section.folder, count: section.chats.count, isExpanded: isExpanded) {
                    if isExpanded {
                        collapsedFolders.insert(section.id)
                    } else {
                        collapsedFolders.remove(section.id)
                    }
                }
                .contextMenu {
                    Button {
                        folderName = section.folder.name
                        renamingFolder = section.folder
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deletingFolder = section.folder
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .modifier(HistoryRowStyle())
                if isExpanded {
                    ForEach(section.chats) { summary in
                        chatRow(summary)
                            .padding(.leading, 24)
                    }
                }
            }
        } header: {
            foldersHeader
                .listRowInsets(EdgeInsets())
                .background(Color.appBackground)
        }
    }
    
    private var foldersHeader: some View {
        HStack {
            SectionTitle(text: Text("Folders"))
            Spacer()
            Button {
                chatForNewFolder = nil
                folderName = ""
                isCreatingFolder = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppGradient.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("New folder"))
        }
        .padding(.trailing, 4)
    }
    
    private func chatSection(_ title: Text, chats: [ChatSummary]) -> some View {
        Section {
            ForEach(chats) { summary in
                chatRow(summary)
            }
        } header: {
            SectionTitle(text: title)
                .background(Color.appBackground)
        }
    }
    
    private func chatRow(_ summary: ChatSummary) -> some View {
        Button {
            router.push(.chat(chatId: summary.id))
        } label: {
            ChatHistoryRow(summary: summary)
        }
        .buttonStyle(PressableButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                deleting = summary
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button {
                newTitle = summary.chat.title
                renaming = summary
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.orange)
            Button {
                moving = summary
            } label: {
                Label("Move", systemImage: "folder")
            }
            .tint(.appGradientStart)
        }
        .modifier(HistoryRowStyle())
    }
    
    private func title(for group: HistoryViewModel.DateGroup) -> Text {
        switch group {
            case .today:
                Text("Today")
            case .yesterday:
                Text("Yesterday")
            case let .day(date):
                Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
                    ? Text(date.formatted(.dateTime.month(.wide).day()))
                    : Text(date.formatted(.dateTime.month(.wide).day().year()))
        }
    }
    
    @ViewBuilder
    private var videos: some View {
        if model.isVideosEmpty {
            EmptyHistoryView(
                icon: "IconImageToImage",
                title: "No videos yet",
                subtitle: "Create your first video to see it here"
            )
        } else {
            GeometryReader { proxy in
                ScrollView {
                    MasonryGrid(items: model.videos, width: proxy.size.width - AppMetrics.sideInset * 2, spacing: 8) { generation in
                        VideoHistoryCard(
                            generation: generation,
                            thumbnails: thumbnails,
                            media: media,
                            player: playback.player(for: generation.id)
                        ) {
                            router.push(.generation(id: generation.id))
                        } onRetry: {
                            Task { await model.retry(generation.id) }
                        }
                        .previewFrame(id: generation.id)
                    } height: { generation, width in
                        width / generation.aspect.ratio
                    }
                    .padding(.horizontal, AppMetrics.sideInset)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    .animation(.easeInOut(duration: 0.25), value: model.videos)
                }
                .previewPlayback(playback)
            }
        }
    }
    
    private var isPlaybackActive: Bool {
        isOnScreen && scenePhase == .active && model.tab == .video
    }
    
    private func isPresented<Item>(_ item: Binding<Item?>) -> Binding<Bool> {
        Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
    }
}
