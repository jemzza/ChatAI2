//
//  Chat.swift
//  AIChat2
//

import Foundation

nonisolated struct Chat: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var folderId: UUID?
    var pinnedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        folderId: UUID? = nil,
        pinnedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.folderId = folderId
        self.pinnedAt = pinnedAt
    }
}

nonisolated struct ChatSummary: Identifiable, Hashable, Sendable {
    let chat: Chat
    let lastMessage: String?
    
    var id: UUID { chat.id }
}
