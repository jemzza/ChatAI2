import Foundation

nonisolated struct PixverseClient: VideoAPI {
    private struct Catalog: Decodable {
        let templates: [Template]
    }
    
    private struct Template: Decodable {
        let templateId: Int64
        let name: String
        let category: String?
        let duration: Int?
        let previewSmall: String?
        let previewLarge: String?
        let qualities: [String]?
        let isActive: FlexibleBool?
    }
    
    private struct FlexibleBool: Decodable {
        let value: Bool
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let bool = try? container.decode(Bool.self) {
                value = bool
            } else {
                value = try container.decode(Int.self) != 0
            }
        }
    }
    
    private struct CreateResponse: Decodable {
        let videoId: Int64
    }
    
    private struct StatusResponse: Decodable {
        let status: String
        let videoUrl: String?
    }
    
    let client: any NetworkClient
    let appID: String
    let catalogCacheURL: URL?
    
    func templates() async throws -> [VideoTemplate] {
        let data: Data
        do {
            data = try await client.data(for: .get("api/v1/get_templates/\(appID)"))
            if let catalogCacheURL { try? data.write(to: catalogCacheURL, options: .atomic) }
        } catch let error as APIError where error.kind == .offline {
            guard let catalogCacheURL, let cached = try? Data(contentsOf: catalogCacheURL) else { throw error }
            data = cached
        }
        return try Self.decodeTemplates(data)
    }
    
    func createVideo(templateId: Int64, imageJPEG: Data, quality: VideoQuality, duration: Int?) async throws -> Int64 {
        var body = MultipartBody()
        body.add(String(templateId), for: "template_id")
        body.add(quality.rawValue, for: "quality")
        if let duration { body.add(String(duration), for: "duration") }
        body.add(file: imageJPEG, name: "image", fileName: "photo.jpg", mimeType: "image/jpeg")
        let response: CreateResponse = try await client.request(.post("api/v1/template2video", multipart: body))
        return response.videoId
    }
    
    func status(serverId: Int64) async throws -> VideoServerStatus {
        let endpoint = Endpoint.get("api/v1/status", query: [URLQueryItem(name: "id", value: String(serverId))])
        let response: StatusResponse = try await client.request(endpoint)
        switch response.status {
            case "success":
                guard let url = response.videoUrl.flatMap(URL.init(string:)) else { throw APIError(kind: .decoding) }
                return .succeeded(url)
            case "error":
                return .failed
            default:
                return .generating
        }
    }
    
    static func decodeTemplates(_ data: Data) throws -> [VideoTemplate] {
        guard let catalog = try? JSONDecoder.snakeCase.decode(Catalog.self, from: data) else {
            throw APIError(kind: .decoding)
        }
        return catalog.templates
            .filter { $0.isActive?.value ?? true }
            .map { template in
                VideoTemplate(
                    id: template.templateId,
                    name: template.name,
                    category: template.category ?? "",
                    previewURL: (template.previewSmall ?? template.previewLarge).flatMap(URL.init(string:)),
                    qualities: (template.qualities ?? []).compactMap(VideoQuality.init(rawValue:)),
                    duration: template.duration
                )
            }
    }
}
