//
//  ChatServiceTests.swift
//  AIChat2Tests
//

import Foundation
import Testing
@testable import AIChat2

@MainActor
struct ChatServiceTests {
    private let repository: GRDBChatRepository
    private let provider = FakeChatProvider(script: .reply("Hi there"))
    private let connectivity = FakeConnectivityMonitor(isOnline: false)
    private let service: ChatService

    init() throws {
        repository = GRDBChatRepository(database: try AppDatabase.inMemory())
        service = ChatService(repository: repository, provider: provider, connectivity: connectivity)
    }

    @Test func offlineMessageIsSentOnceWhenNetworkReturns() async throws {
        let chatId = try await service.send("Hello", inChat: nil)
        #expect(try await repository.pendingMessages().map(\.text) == ["Hello"])
        #expect(provider.requests.isEmpty)

        connectivity.setOnline(true)
        async let first: Void = service.processOutbox()
        async let second: Void = service.processOutbox()
        _ = await (first, second)
        let messages = try await messages(in: chatId) { $0.last?.status == .done }

        #expect(provider.requests == [FakeChatProvider.Request(chatId: chatId, text: "Hello")])
        #expect(messages.map(\.status) == [.sent, .done])
        #expect(messages.last?.text == "Hi there")
    }

    @Test func failedReplyKeepsErrorAndRetryAsksSameQuestion() async throws {
        connectivity.setOnline(true)
        provider.setScript(.fail(APIError(kind: .rateLimited, retryAfter: .seconds(30))))
        let chatId = try await service.send("Plan my day", inChat: nil)
        let failed = try await messages(in: chatId) { $0.last?.status == .failed }
        #expect(failed.last?.failure?.kind == .rateLimited)
        #expect(failed.last?.failure?.retryAt != nil)

        provider.setScript(.reply("Here is your plan"))
        let replyId = try #require(failed.last?.id)
        try await service.retry(assistantMessageId: replyId, inChat: chatId)
        let retried = try await messages(in: chatId) { $0.last?.status == .done }

        #expect(provider.requests.map(\.text) == ["Plan my day", "Plan my day"])
        #expect(retried.last?.id == replyId)
        #expect(retried.last?.failure == nil)
        #expect(retried.count == 2)
    }

    @Test func generatingRepliesBecomeInterruptedOnLaunch() async throws {
        connectivity.setOnline(true)
        provider.setScript(.hang)
        let chatId = try await service.send("Long question", inChat: nil)
        _ = try await messages(in: chatId) { $0.last?.status == .generating }

        #expect(try await repository.markGeneratingAsInterrupted() == 1)
        let messages = try await messages(in: chatId) { $0.last?.status == .interrupted }
        #expect(messages.last?.status.isRetryable == true)
    }

    private func messages(
        in chatId: UUID,
        until condition: @escaping @Sendable ([Message]) -> Bool
    ) async throws -> [Message] {
        let stream = repository.observeMessages(chatId: chatId)
        let result = await withTaskGroup(of: [Message]?.self) { group in
            group.addTask {
                for await messages in stream where condition(messages) { return messages }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        return try #require(result)
    }
}
