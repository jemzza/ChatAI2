//
//  ChatRecord.swift
//  AIChat2
//

import Foundation
import GRDB

nonisolated struct ChatRecord: Codable, Hashable, Sendable {
    static let databaseTableName = "chat"
    
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var folderId: UUID?
    var pinnedAt: Date?
    
    enum Columns {
        static let title = Column(CodingKeys.title)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
        static let folderId = Column(CodingKeys.folderId)
        static let pinnedAt = Column(CodingKeys.pinnedAt)
    }
}

nonisolated extension ChatRecord: FetchableRecord, PersistableRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy {
        .timeIntervalSinceReferenceDate
    }
    
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy {
        .timeIntervalSinceReferenceDate
    }
}

nonisolated extension ChatRecord {
    init(_ chat: Chat) {
        id = chat.id
        title = chat.title
        createdAt = chat.createdAt
        updatedAt = chat.updatedAt
        folderId = chat.folderId
        pinnedAt = chat.pinnedAt
    }
    
    var chat: Chat {
        Chat(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            folderId: folderId,
            pinnedAt: pinnedAt
        )
    }
}
