import Foundation

nonisolated enum MessageRole: String, Hashable, Sendable {
    case user
    case assistant
}

nonisolated enum MessageStatus: String, Hashable, Sendable {
    case pending
    case sent
    case generating
    case done
    case failed
    case interrupted
    
    var isRetryable: Bool {
        switch self {
            case .done, .failed, .interrupted: true
            case .pending, .sent, .generating: false
        }
    }
}

nonisolated struct Message: Identifiable, Hashable, Sendable {
    let id: UUID
    let chatId: UUID
    let role: MessageRole
    var text: String
    var status: MessageStatus
    var failure: MessageFailure?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        chatId: UUID,
        role: MessageRole,
        text: String,
        status: MessageStatus,
        failure: MessageFailure? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.chatId = chatId
        self.role = role
        self.text = text
        self.status = status
        self.failure = failure
        self.createdAt = createdAt
    }
}
