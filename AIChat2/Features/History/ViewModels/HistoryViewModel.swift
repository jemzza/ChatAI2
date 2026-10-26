import Combine
import Foundation

final class HistoryViewModel: ObservableObject {
    enum DateGroup: Hashable {
        case today
        case yesterday
        case day(Date)
    }
    
    struct FolderSection: Identifiable, Hashable {
        let folder: Folder
        let chats: [ChatSummary]
        var id: UUID { folder.id }
    }
    
    struct ChatSection: Identifiable, Hashable {
        let group: DateGroup
        let chats: [ChatSummary]
        var id: DateGroup { group }
    }
    
    @Published var tab: HistoryTab
    @Published private(set) var pinned: [ChatSummary] = []
    @Published private(set) var folders: [FolderSection] = []
    @Published private(set) var sections: [ChatSection] = []
    @Published private(set) var videos: [VideoGeneration] = []
    @Published private(set) var hasLoadedChats = false
    @Published private(set) var hasLoadedVideos = false
    
    private let chats: any ChatRepository
    private let chatService: ChatService
    private let videoRepository: any VideoRepository
    private let videoService: VideoGenerationService
    private let calendar: Calendar
    private let now: () -> Date
    private var latestSummaries: [ChatSummary] = []
    private var latestFolders: [Folder] = []
    
    init(
        tab: HistoryTab,
        chats: any ChatRepository,
        chatService: ChatService,
        videoRepository: any VideoRepository,
        videoService: VideoGenerationService,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.tab = tab
        self.chats = chats
        self.chatService = chatService
        self.videoRepository = videoRepository
        self.videoService = videoService
        self.calendar = calendar
        self.now = now
    }
    
    var isChatsEmpty: Bool { hasLoadedChats && pinned.isEmpty && sections.isEmpty && folders.isEmpty }
    var isVideosEmpty: Bool { hasLoadedVideos && videos.isEmpty }
    var allFolders: [Folder] { folders.map(\.folder) }
    
    func observe() async {
        async let summaries: Void = observeSummaries()
        async let folders: Void = observeFolders()
        async let videos: Void = observeVideos()
        _ = await (summaries, folders, videos)
    }
    
    func apply(_ summaries: [ChatSummary], folders: [Folder]) {
        pinned = summaries
            .filter { $0.chat.pinnedAt != nil }
            .sorted { ($0.chat.pinnedAt ?? .distantPast) > ($1.chat.pinnedAt ?? .distantPast) }
        let unpinned = summaries.filter { $0.chat.pinnedAt == nil }
        let known = Set(folders.map(\.id))
        self.folders = folders.map { folder in
            FolderSection(folder: folder, chats: unpinned.filter { $0.chat.folderId == folder.id })
        }
        var sections: [ChatSection] = []
        for summary in unpinned where summary.chat.folderId.map({ !known.contains($0) }) ?? true {
            let group = group(for: summary.chat.updatedAt)
            if let last = sections.last, last.group == group {
                sections[sections.count - 1] = ChatSection(group: group, chats: last.chats + [summary])
            } else {
                sections.append(ChatSection(group: group, chats: [summary]))
            }
        }
        self.sections = sections
    }
    
    static func isValidName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func rename(_ chatId: UUID, to title: String) async {
        guard Self.isValidName(title) else { return }
        try? await chats.renameChat(id: chatId, title: title.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func delete(_ chatId: UUID) async {
        try? await chatService.deleteChat(id: chatId)
    }
    
    func createFolder(named name: String, moving chatId: UUID? = nil) async {
        guard Self.isValidName(name) else { return }
        let folder = Folder(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), createdAt: now())
        do {
            try await chats.createFolder(folder)
            if let chatId { try await chats.moveChat(id: chatId, toFolder: folder.id) }
        } catch {
            return
        }
    }
    
    func renameFolder(_ folderId: UUID, to name: String) async {
        guard Self.isValidName(name) else { return }
        try? await chats.renameFolder(id: folderId, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func deleteFolder(_ folderId: UUID) async {
        try? await chats.deleteFolder(id: folderId)
    }
    
    func move(_ chatId: UUID, toFolder folderId: UUID?) async {
        try? await chats.moveChat(id: chatId, toFolder: folderId)
    }
    
    func retry(_ generationId: UUID) async {
        try? await videoService.retry(id: generationId)
    }
    
    private func observeSummaries() async {
        for await summaries in chats.observeChatSummaries() {
            latestSummaries = summaries
            apply(summaries, folders: latestFolders)
            hasLoadedChats = true
        }
    }
    
    private func observeFolders() async {
        for await folders in chats.observeFolders() {
            latestFolders = folders
            apply(latestSummaries, folders: folders)
        }
    }
    
    private func observeVideos() async {
        for await generations in videoRepository.observeGenerations() {
            videos = generations
            hasLoadedVideos = true
        }
    }
    
    private func group(for date: Date) -> DateGroup {
        let today = calendar.startOfDay(for: now())
        let day = calendar.startOfDay(for: date)
        if day == today { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), day == yesterday { return .yesterday }
        return .day(day)
    }
}
