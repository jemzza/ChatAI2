import Foundation

final class ChatService {
    private struct Generation {
        let messageId: UUID
        var task: Task<Void, Never>?
        var interruptedBySystem = false
    }

    private let repository: any ChatRepository
    private let provider: any ChatProvider
    private let connectivity: any ConnectivityMonitoring
    private let backgroundTasks: (any BackgroundTaskScheduling)?
    private let notifier: (any ActivityNotifying)?
    private let now: () -> Date

    private var generations: [UUID: Generation] = [:]
    private var isProcessingOutbox = false
    private var isOutboxRerunRequested = false

    init(
        repository: any ChatRepository,
        provider: any ChatProvider,
        connectivity: any ConnectivityMonitoring,
        backgroundTasks: (any BackgroundTaskScheduling)? = nil,
        notifier: (any ActivityNotifying)? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.provider = provider
        self.connectivity = connectivity
        self.backgroundTasks = backgroundTasks
        self.notifier = notifier
        self.now = now
    }

    func isGenerating(chatId: UUID) -> Bool {
        generations[chatId] != nil
    }

    func run() async {
        for await isOnline in connectivity.updates() where isOnline {
            await processOutbox()
        }
    }

    func appDidBecomeActive() {
        Task { await processOutbox() }
    }

    @discardableResult
    func send(_ text: String, inChat chatId: UUID?) async throws -> UUID {
        let date = now()
        let chatId = chatId ?? UUID()
        let message = Message(chatId: chatId, role: .user, text: text, status: .pending, createdAt: date)
        if try await repository.chat(id: chatId) != nil {
            try await repository.insertMessage(message)
        } else {
            let chat = Chat(id: chatId, title: Self.title(from: text), createdAt: date)
            try await repository.insertChat(chat, firstMessage: message)
        }
        if connectivity.isOnline, generations[chatId] == nil {
            _ = try await claimAndGenerate(message)
        }
        return chatId
    }

    func retry(assistantMessageId: UUID, inChat chatId: UUID) async throws {
        guard generations[chatId] == nil,
              let question = try await repository.question(before: assistantMessageId),
              try await repository.claimRetry(assistantMessageId: assistantMessageId),
              generations[chatId] == nil
        else { return }
        startGeneration(chatId: chatId, messageId: assistantMessageId, question: question.text)
    }

    func deleteChat(id: UUID) async throws {
        generations[id]?.task?.cancel()
        try await repository.deleteChat(id: id)
    }

    func deleteAll() async throws {
        for generation in generations.values { generation.task?.cancel() }
        try await repository.deleteAll()
    }

    func processOutbox() async {
        guard !isProcessingOutbox else {
            isOutboxRerunRequested = true
            return
        }
        isProcessingOutbox = true
        await drainOutbox()
        isProcessingOutbox = false
    }

    private func drainOutbox() async {
        repeat {
            isOutboxRerunRequested = false
            guard connectivity.isOnline, let pending = try? await repository.pendingMessages() else { return }
            for message in pending {
                guard connectivity.isOnline else { return }
                guard generations[message.chatId] == nil else { continue }
                guard let task = try? await claimAndGenerate(message) else { continue }
                await task.value
            }
        } while isOutboxRerunRequested
    }

    private func claimAndGenerate(_ message: Message) async throws -> Task<Void, Never>? {
        let reply = Message(
            chatId: message.chatId,
            role: .assistant,
            text: "",
            status: .generating,
            createdAt: message.createdAt.addingTimeInterval(0.001)
        )
        guard try await repository.claimPending(messageId: message.id, reply: reply) else { return nil }
        return startGeneration(chatId: message.chatId, messageId: reply.id, question: message.text)
    }

    @discardableResult
    private func startGeneration(chatId: UUID, messageId: UUID, question: String) -> Task<Void, Never> {
        generations[chatId] = Generation(messageId: messageId)
        let task = Task { [weak self] () -> Void in
            await self?.generate(chatId: chatId, messageId: messageId, question: question)
        }
        generations[chatId]?.task = task
        return task
    }

    private func generate(chatId: UUID, messageId: UUID, question: String) async {
        let backgroundToken = backgroundTasks?.beginTask { [weak self] in
            self?.generations[chatId]?.interruptedBySystem = true
            self?.generations[chatId]?.task?.cancel()
        }
        defer {
            if let backgroundToken { backgroundTasks?.endTask(backgroundToken) }
        }

        var text = ""
        var failure: MessageFailure?
        do {
            text = try await provider.reply(to: question, inChat: chatId)
        } catch let error as APIError {
            failure = MessageFailure(kind: error.kind, retryAt: error.retryAfter.map(retryDate(after:)))
        } catch {
            if !Task.isCancelled { failure = MessageFailure(kind: .unknown) }
        }

        let status: MessageStatus
        if generations[chatId]?.interruptedBySystem == true || (Task.isCancelled && failure == nil) {
            status = .interrupted
            failure = nil
        } else if failure != nil {
            status = .failed
        } else {
            status = .done
        }

        let repository = repository
        let result = (text: text, failure: failure)
        let saved = await Task {
            (try? await repository.updateMessage(id: messageId, text: result.text, status: status, failure: result.failure)) != nil
        }.value
        if saved, status == .done {
            await notifier?.replyDidFinish(text: result.text)
        }
        finishGeneration(chatId: chatId, messageId: messageId)
    }

    private func finishGeneration(chatId: UUID, messageId: UUID) {
        guard generations[chatId]?.messageId == messageId else { return }
        generations[chatId] = nil
        if connectivity.isOnline {
            Task { await processOutbox() }
        }
    }

    private func retryDate(after duration: Duration) -> Date {
        let (seconds, attoseconds) = duration.components
        return now().addingTimeInterval(Double(seconds) + Double(attoseconds) / 1e18)
    }

    static func title(from text: String, maxLength: Int = 40) -> String {
        let line = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard line.count > maxLength else { return line }
        let head = line.prefix(maxLength - 1)
        if let space = head.lastIndex(of: " "), head.distance(from: head.startIndex, to: space) >= maxLength / 2 {
            return head[..<space] + "…"
        }
        return head + "…"
    }
}
