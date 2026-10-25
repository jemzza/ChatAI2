import Foundation

nonisolated struct DolaChatProvider: ChatProvider {
    private struct Request: Encodable {
        let message: String
    }
    
    private struct Response: Decodable {
        let assistantMessage: String
    }
    
    let client: any NetworkClient
    
    func reply(to text: String, inChat chatId: UUID) async throws -> String {
        let path = "dola/chats/\(chatId.uuidString.lowercased())/messages"
        let response: Response = try await client.request(.post(path, json: Request(message: text)))
        return response.assistantMessage
    }
}
