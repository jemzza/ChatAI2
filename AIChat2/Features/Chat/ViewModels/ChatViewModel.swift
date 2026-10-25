import Combine
import SwiftUI

final class ChatViewModel: ObservableObject {
    static let suggestions: [LocalizedStringResource] = [
        "Help me write an email",
        "Explain it simply",
        "Translate a text",
        "Plan my day"
    ]
    
    @Published private(set) var chatId: UUID?
    @Published private(set) var chat: Chat?
    @Published private(set) var messages: [Message] = []
    @Published var draft = ""
    @Published var toast: ToastMessage?
    
    var onPaywall: () -> Void = {}
    
    private let repository: any ChatRepository
    private let service: ChatService
    private let subscription: any SubscribableService
    private let copyToPasteboard: (String) -> Bool
    private let now: () -> Date
    
    init(
        chatId: UUID?,
        repository: any ChatRepository,
        service: ChatService,
        subscription: any SubscribableService,
        copyToPasteboard: @escaping (String) -> Bool,
        now: @escaping () -> Date = Date.init
    ) {
        self.chatId = chatId
        self.repository = repository
        self.service = service
        self.subscription = subscription
        self.copyToPasteboard = copyToPasteboard
        self.now = now
    }
    
    var isEmpty: Bool { messages.isEmpty }
    var isGenerating: Bool { messages.contains { $0.status == .generating } }
    var canSend: Bool { !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating }
    var date: Date { chat?.createdAt ?? now() }
    var isPinned: Bool { chat?.pinnedAt != nil }
    var hasMenu: Bool { chat != nil }
    
    var shareText: String {
        messages
            .filter { !$0.text.isEmpty && $0.status != .generating }
            .map(\.text)
            .joined(separator: "\n\n")
    }
    
    func canRegenerate(_ message: Message) -> Bool {
        message.role == .assistant
            && message.status == .done
            && message.id == messages.last(where: { $0.role == .assistant })?.id
    }
    
    func observe() async {
        guard let chatId else { return }
        async let chat: Void = observeChat(chatId)
        async let messages: Void = observeMessages(chatId)
        _ = await (chat, messages)
    }
    
    func useSuggestion(_ suggestion: LocalizedStringResource) {
        draft = String(localized: suggestion)
    }
    
    func send() async {
        guard canSend else { return }
        guard subscription.isPremium else {
            onPaywall()
            return
        }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        do {
            let sentChatId = try await service.send(text, inChat: chatId)
            if chatId == nil { chatId = sentChatId }
        } catch {
            draft = text
            toast = ToastMessage(kind: .failure, text: "Couldn't send message")
        }
    }
    
    func retry(_ message: Message) async {
        guard let chatId else { return }
        guard subscription.isPremium else {
            onPaywall()
            return
        }
        try? await service.retry(assistantMessageId: message.id, inChat: chatId)
    }
    
    func copy(_ message: Message) {
        let copied = !message.text.isEmpty && copyToPasteboard(message.text)
        toast = copied
            ? ToastMessage(kind: .success, text: "Copied")
            : ToastMessage(kind: .failure, text: "Copy failed")
    }
    
    func togglePin() async {
        guard let chatId else { return }
        try? await repository.setPinned(chatId: chatId, at: isPinned ? nil : now())
    }
    
    func deleteChat() async -> Bool {
        guard let chatId else { return false }
        do {
            try await service.deleteChat(id: chatId)
            return true
        } catch {
            toast = ToastMessage(kind: .failure, text: "Couldn't delete chat")
            return false
        }
    }
    
    private func observeChat(_ chatId: UUID) async {
        for await summaries in repository.observeChatSummaries() {
            chat = summaries.first { $0.id == chatId }?.chat
        }
    }
    
    private func observeMessages(_ chatId: UUID) async {
        for await messages in repository.observeMessages(chatId: chatId) {
            self.messages = messages
        }
    }
}
