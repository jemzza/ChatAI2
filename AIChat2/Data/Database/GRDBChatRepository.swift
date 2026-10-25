//
//  GRDBChatRepository.swift
//  AIChat2
//

import Foundation
import GRDB

nonisolated final class GRDBChatRepository: ChatRepository {
    private let writer: any DatabaseWriter
    private let observationQueue = DispatchQueue(label: "GRDBChatRepository.observation")

    init(database: AppDatabase) {
        writer = database.writer
    }

    func observeChatSummaries() -> AsyncStream<[ChatSummary]> {
        writer.observe(on: observationQueue) { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT chat.*,
                       (SELECT message.text FROM message
                        WHERE message.chatId = chat.id AND message.text <> ''
                        ORDER BY message.createdAt DESC, message.rowid DESC LIMIT 1) AS lastMessage
                FROM chat
                ORDER BY chat.updatedAt DESC, chat.rowid DESC
                """)
            return try rows.map { row in
                ChatSummary(chat: try ChatRecord(row: row).chat, lastMessage: row["lastMessage"])
            }
        }
    }

    func observeFolders() -> AsyncStream<[Folder]> {
        writer.observe(on: observationQueue) { db in
            try FolderRecord
                .order(FolderRecord.Columns.createdAt, Column.rowID)
                .fetchAll(db)
                .map(\.folder)
        }
    }

    func observeMessages(chatId: UUID) -> AsyncStream<[Message]> {
        writer.observe(on: observationQueue) { db in
            try MessageRecord.chronological()
                .filter(MessageRecord.Columns.chatId == chatId)
                .fetchAll(db)
                .map(\.message)
        }
    }

    func chat(id: UUID) async throws -> Chat? {
        try await writer.read { db in
            try ChatRecord.fetchOne(db, key: id)?.chat
        }
    }

    func insertChat(_ chat: Chat, firstMessage: Message) async throws {
        var record = ChatRecord(chat)
        record.updatedAt = firstMessage.createdAt
        try await writer.write { [record] db in
            try Self.requireFolder(record.folderId, db)
            try record.insert(db)
            try MessageRecord(firstMessage).insert(db)
        }
    }

    func renameChat(id: UUID, title: String) async throws {
        let changed = try await writer.write { db in
            try ChatRecord.filter(key: id).updateAll(db, ChatRecord.Columns.title.set(to: title))
        }
        guard changed > 0 else { throw RepositoryError.chatNotFound(id) }
    }

    func setPinned(chatId: UUID, at pinnedAt: Date?) async throws {
        let changed = try await writer.write { db in
            try ChatRecord.filter(key: chatId)
                .updateAll(db, ChatRecord.Columns.pinnedAt.set(to: pinnedAt?.databaseTimestamp))
        }
        guard changed > 0 else { throw RepositoryError.chatNotFound(chatId) }
    }

    func moveChat(id: UUID, toFolder folderId: UUID?) async throws {
        try await writer.write { db in
            guard try ChatRecord.exists(db, key: id) else { throw RepositoryError.chatNotFound(id) }
            try Self.requireFolder(folderId, db)
            try ChatRecord.filter(key: id).updateAll(db, ChatRecord.Columns.folderId.set(to: folderId))
        }
    }

    func deleteChat(id: UUID) async throws {
        _ = try await writer.write { db in
            try ChatRecord.deleteOne(db, key: id)
        }
    }

    func deleteAll() async throws {
        try await writer.write { db in
            _ = try ChatRecord.deleteAll(db)
            _ = try FolderRecord.deleteAll(db)
        }
    }

    func createFolder(_ folder: Folder) async throws {
        try await writer.write { db in
            try FolderRecord(folder).insert(db)
        }
    }

    func renameFolder(id: UUID, name: String) async throws {
        let changed = try await writer.write { db in
            try FolderRecord.filter(key: id).updateAll(db, FolderRecord.Columns.name.set(to: name))
        }
        guard changed > 0 else { throw RepositoryError.folderNotFound(id) }
    }

    func deleteFolder(id: UUID) async throws {
        _ = try await writer.write { db in
            try FolderRecord.deleteOne(db, key: id)
        }
    }

    func insertMessage(_ message: Message) async throws {
        try await writer.write { db in
            guard try ChatRecord.exists(db, key: message.chatId) else {
                throw RepositoryError.chatNotFound(message.chatId)
            }
            try Self.append(message, db)
        }
    }

    func updateMessage(id: UUID, text: String, status: MessageStatus, failure: MessageFailure?) async throws {
        let changed = try await writer.write { db in
            try MessageRecord.filter(key: id).updateAll(db, [
                MessageRecord.Columns.text.set(to: text),
                MessageRecord.Columns.status.set(to: status.rawValue),
                MessageRecord.Columns.failureKind.set(to: failure?.kind.rawValue),
                MessageRecord.Columns.failureRetryAt.set(to: failure?.retryAt?.databaseTimestamp)
            ])
        }
        guard changed > 0 else { throw RepositoryError.messageNotFound(id) }
    }

    func question(before assistantMessageId: UUID) async throws -> Message? {
        try await writer.read { db in
            guard let reply = try MessageRecord.fetchOne(db, key: assistantMessageId) else {
                throw RepositoryError.messageNotFound(assistantMessageId)
            }
            let messages = try MessageRecord.chronological()
                .filter(MessageRecord.Columns.chatId == reply.chatId)
                .fetchAll(db)
            guard let index = messages.firstIndex(where: { $0.id == assistantMessageId }) else { return nil }
            return messages[..<index].last { $0.role == MessageRole.user.rawValue }?.message
        }
    }

    func pendingMessages() async throws -> [Message] {
        try await writer.read { db in
            try MessageRecord.chronological()
                .filter(MessageRecord.Columns.role == MessageRole.user.rawValue)
                .filter(MessageRecord.Columns.status == MessageStatus.pending.rawValue)
                .fetchAll(db)
                .map(\.message)
        }
    }

    func claimPending(messageId: UUID, reply: Message) async throws -> Bool {
        try await writer.write { db in
            guard let stored = try MessageRecord.fetchOne(db, key: messageId) else {
                throw RepositoryError.messageNotFound(messageId)
            }
            guard stored.role == MessageRole.user.rawValue,
                  stored.status == MessageStatus.pending.rawValue else { return false }
            try MessageRecord.filter(key: messageId)
                .updateAll(db, MessageRecord.Columns.status.set(to: MessageStatus.sent.rawValue))
            try Self.append(reply, db)
            return true
        }
    }

    func claimRetry(assistantMessageId: UUID) async throws -> Bool {
        try await writer.write { db in
            guard let stored = try MessageRecord.fetchOne(db, key: assistantMessageId) else {
                throw RepositoryError.messageNotFound(assistantMessageId)
            }
            guard stored.role == MessageRole.assistant.rawValue,
                  MessageStatus(rawValue: stored.status)?.isRetryable == true else { return false }
            try MessageRecord.filter(key: assistantMessageId).updateAll(db, [
                MessageRecord.Columns.status.set(to: MessageStatus.generating.rawValue),
                MessageRecord.Columns.text.set(to: ""),
                MessageRecord.Columns.failureKind.set(to: nil),
                MessageRecord.Columns.failureRetryAt.set(to: nil)
            ])
            return true
        }
    }

    @discardableResult
    func markGeneratingAsInterrupted() async throws -> Int {
        try await writer.write { db in
            try MessageRecord
                .filter(MessageRecord.Columns.status == MessageStatus.generating.rawValue)
                .updateAll(db, MessageRecord.Columns.status.set(to: MessageStatus.interrupted.rawValue))
        }
    }

    private static func requireFolder(_ folderId: UUID?, _ db: Database) throws {
        guard let folderId else { return }
        guard try FolderRecord.exists(db, key: folderId) else {
            throw RepositoryError.folderNotFound(folderId)
        }
    }

    private static func append(_ message: Message, _ db: Database) throws {
        try MessageRecord(message).insert(db)
        try db.execute(
            sql: "UPDATE chat SET updatedAt = MAX(updatedAt, ?) WHERE id = ?",
            arguments: [message.createdAt.databaseTimestamp, message.chatId]
        )
    }
}
