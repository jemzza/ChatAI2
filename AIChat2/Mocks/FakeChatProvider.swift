//
//  FakeChatProvider.swift
//  AIChat2
//

#if DEBUG
import Foundation
import os

nonisolated final class FakeChatProvider: ChatProvider {
    enum Script: Sendable {
        case reply(String)
        case fail(APIError)
        case hang
    }
    
    struct Request: Hashable, Sendable {
        let chatId: UUID
        let text: String
    }
    
    private let script: OSAllocatedUnfairLock<Script>
    private let recorded = OSAllocatedUnfairLock<[Request]>(initialState: [])
    private let delay: Duration
    
    init(script: Script = .reply(FakeChatProvider.sampleReply), delay: Duration = .zero) {
        self.script = OSAllocatedUnfairLock(initialState: script)
        self.delay = delay
    }
    
    var requests: [Request] { recorded.withLock { $0 } }
    
    func setScript(_ script: Script) {
        self.script.withLock { $0 = script }
    }
    
    func reply(to text: String, inChat chatId: UUID) async throws -> String {
        recorded.withLock { $0.append(Request(chatId: chatId, text: text)) }
        if delay > .zero { try await Task.sleep(for: delay) }
        switch script.withLock({ $0 }) {
            case let .reply(text):
                return text
            case let .fail(error):
                throw error
            case .hang:
                try await Task.sleep(for: .seconds(3600))
                throw CancellationError()
        }
    }
    
    static let sampleReply = """
        **Welcome to the team!**
        
        Here are a few tips:
        - Ask questions early;
        - Meet the team on Monday.
        """
}
#endif
