//
//  MessageRecord.swift
//  AIChat2
//

import Foundation
import GRDB

nonisolated struct MessageRecord: Codable, Hashable, Sendable {
    static let databaseTableName = "message"
    
    var id: UUID
    var chatId: UUID
    var role: String
    var text: String
    var status: String
    var failureKind: String?
    var failureRetryAt: Date?
    var createdAt: Date
    
    enum Columns {
        static let chatId = Column(CodingKeys.chatId)
        static let role = Column(CodingKeys.role)
        static let text = Column(CodingKeys.text)
        static let status = Column(CodingKeys.status)
        static let failureKind = Column(CodingKeys.failureKind)
        static let failureRetryAt = Column(CodingKeys.failureRetryAt)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}

nonisolated extension MessageRecord: FetchableRecord, PersistableRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy {
        .timeIntervalSinceReferenceDate
    }
    
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy {
        .timeIntervalSinceReferenceDate
    }
}

nonisolated extension MessageRecord {
    init(_ message: Message) {
        id = message.id
        chatId = message.chatId
        role = message.role.rawValue
        text = message.text
        status = message.status.rawValue
        failureKind = message.failure?.kind.rawValue
        failureRetryAt = message.failure?.retryAt
        createdAt = message.createdAt
    }
    
    var message: Message {
        Message(
            id: id,
            chatId: chatId,
            role: MessageRole(rawValue: role) ?? .assistant,
            text: text,
            status: MessageStatus(rawValue: status) ?? .failed,
            failure: failureKind.map {
                MessageFailure(kind: ErrorKind(rawValue: $0) ?? .unknown, retryAt: failureRetryAt)
            },
            createdAt: createdAt
        )
    }
    
    static func chronological() -> QueryInterfaceRequest<MessageRecord> {
        order(Columns.createdAt, Column.rowID)
    }
}
