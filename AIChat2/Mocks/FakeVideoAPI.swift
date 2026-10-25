#if DEBUG
import Foundation
import os

nonisolated final class FakeVideoAPI: VideoAPI {
    private struct State {
        var templates: Result<[VideoTemplate], APIError>
        var createResult: Result<Int64, APIError> = .success(900_001)
        var statuses: [Result<VideoServerStatus, APIError>]
        var createdTemplateIds: [Int64] = []
        var statusRequests = 0
    }
    
    private let state: OSAllocatedUnfairLock<State>
    
    init(
        templates: Result<[VideoTemplate], APIError> = .success(FakeVideoAPI.sampleTemplates),
        statuses: [Result<VideoServerStatus, APIError>] = [.success(.generating)]
    ) {
        state = OSAllocatedUnfairLock(initialState: State(templates: templates, statuses: statuses))
    }
    
    var createdTemplateIds: [Int64] { state.withLock(\.createdTemplateIds) }
    var statusRequests: Int { state.withLock(\.statusRequests) }
    
    func setCreateResult(_ result: Result<Int64, APIError>) {
        state.withLock { $0.createResult = result }
    }
    
    func setStatuses(_ statuses: [Result<VideoServerStatus, APIError>]) {
        state.withLock { $0.statuses = statuses }
    }
    
    func templates() async throws -> [VideoTemplate] {
        try state.withLock(\.templates).get()
    }
    
    func createVideo(templateId: Int64, imageJPEG: Data, quality: VideoQuality, duration: Int?) async throws -> Int64 {
        try state.withLock { state in
            state.createdTemplateIds.append(templateId)
            return state.createResult
        }.get()
    }
    
    func status(serverId: Int64) async throws -> VideoServerStatus {
        try state.withLock { state in
            state.statusRequests += 1
            return state.statuses.count > 1 ? state.statuses.removeFirst() : state.statuses.first ?? .success(.generating)
        }.get()
    }
    
    static let sampleTemplates: [VideoTemplate] = [
        sample(1, "Clay Fool", "📈 Trending"),
        sample(2, "Dense Snowflakes", "💃 Dance"),
        sample(3, "Warm Light", "💛 Warm"),
        sample(4, "Disco Night", "💃 Dance"),
        sample(5, "Golden Hour", "📈 Trending"),
        sample(6, "Snow Globe", "❄️ Winter Vibe")
    ]
    
    private static func sample(_ id: Int64, _ name: String, _ category: String) -> VideoTemplate {
        VideoTemplate(
            id: id,
            name: name,
            category: category,
            previewURL: URL(string: "https://media.example.test/templates/\(id).mp4"),
            qualities: [.p720, .p1080],
            duration: 5
        )
    }
}

nonisolated struct FakeVideoThumbnails: VideoThumbnailing {
    func thumbnail(for url: URL, maxPixelSize: Int) async -> Data? {
        if url.isFileURL { return await VideoThumbnailService.firstFrame(of: url, maxPixelSize: maxPixelSize) }
        let hue = Double(abs(url.absoluteString.hashValue % 360)) / 360
        return await SolidImage.jpeg(hue: hue)
    }
}
#endif
