import Foundation
import Testing
@testable import AIChat2

struct PixverseClientTests {
    private struct StubClient: NetworkClient {
        let body: String

        func data(for endpoint: Endpoint) async throws -> Data {
            Data(body.utf8)
        }
    }

    @Test func decodesActiveTemplates() throws {
        let json = """
            {"templates": [
                {"id": 1, "template_id": 315, "name": "Clay Fool", "category": "📈 Trending",
                 "preview_small": "https://cdn.test/315.mp4", "qualities": ["720p", "1080p", "4k"],
                 "duration": 5, "is_active": 1},
                {"id": 2, "template_id": 316, "name": "Hidden", "category": "📈 Trending", "is_active": 0},
                {"id": 3, "template_id": 317, "name": "Bool Flag", "is_active": true}
            ]}
            """
        let templates = try PixverseClient.decodeTemplates(Data(json.utf8))

        #expect(templates.map(\.id) == [315, 317])
        #expect(templates[0].qualities == [.p720, .p1080])
        #expect(templates[0].previewURL?.absoluteString == "https://cdn.test/315.mp4")
        #expect(templates[1].category.isEmpty)
    }

    @Test func mapsGenerationStatus() async throws {
        let success = PixverseClient(
            client: StubClient(body: #"{"status": "success", "video_url": "https://cdn.test/v.mp4"}"#),
            appID: "app",
            catalogCacheURL: nil
        )
        let generating = PixverseClient(client: StubClient(body: #"{"status": "generating"}"#), appID: "app", catalogCacheURL: nil)
        let failed = PixverseClient(client: StubClient(body: #"{"status": "error"}"#), appID: "app", catalogCacheURL: nil)

        #expect(try await success.status(serverId: 1) == .succeeded(URL(string: "https://cdn.test/v.mp4")!))
        #expect(try await generating.status(serverId: 1) == .generating)
        #expect(try await failed.status(serverId: 1) == .failed)
    }
}
