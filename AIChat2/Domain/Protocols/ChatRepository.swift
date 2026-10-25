//
//  ChatRepository.swift
//  AIChat2
//

import Foundation

nonisolated protocol ChatRepository: Sendable {
    func observeChatSummaries() -> AsyncStream<[ChatSummary]>
    func observeFolders() -> AsyncStream<[Folder]>
    func observeMessages(chatId: UUID) -> AsyncStream<[Message]>
    func chat(id: UUID) async throws -> Chat?
    
    func insertChat(_ chat: Chat, firstMessage: Message) async throws
    func renameChat(id: UUID, title: String) async throws
    func setPinned(chatId: UUID, at pinnedAt: Date?) async throws
    func moveChat(id: UUID, toFolder folderId: UUID?) async throws
    func deleteChat(id: UUID) async throws
    func deleteAll() async throws
    
    func createFolder(_ folder: Folder) async throws
    func renameFolder(id: UUID, name: String) async throws
    func deleteFolder(id: UUID) async throws
    
    func insertMessage(_ message: Message) async throws
    func updateMessage(id: UUID, text: String, status: MessageStatus, failure: MessageFailure?) async throws
    func question(before assistantMessageId: UUID) async throws -> Message?
    
    func pendingMessages() async throws -> [Message]
    func claimPending(messageId: UUID, reply: Message) async throws -> Bool
    func claimRetry(assistantMessageId: UUID) async throws -> Bool
    @discardableResult
    func markGeneratingAsInterrupted() async throws -> Int
}
