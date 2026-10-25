import Foundation

nonisolated protocol ChatProvider: Sendable {
    func reply(to text: String, inChat chatId: UUID) async throws -> String
}
