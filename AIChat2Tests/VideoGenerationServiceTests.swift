import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import AIChat2

@MainActor
struct VideoGenerationServiceTests {
    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let repository: GRDBVideoRepository
    private let api = FakeVideoAPI()
    private let service: VideoGenerationService
    private let template = FakeVideoAPI.sampleTemplates[0]

    init() throws {
        repository = GRDBVideoRepository(database: try AppDatabase.inMemory())
        let media = FileMediaStore(
            sourcesDirectory: directory.appendingPathComponent("sources"),
            videosDirectory: directory.appendingPathComponent("videos")
        )
        service = VideoGenerationService(
            repository: repository,
            api: api,
            media: media,
            connectivity: FakeConnectivityMonitor(isOnline: true),
            configuration: .init(pollIntervals: [.milliseconds(10)], maxPolls: 10)
        )
    }

    @Test func pollsUntilReadyAndDownloadsVideo() async throws {
        let remote = try makeRemoteVideo()
        api.setStatuses([.success(.generating), .success(.generating), .success(.succeeded(remote))])

        let id = try await service.create(template: template, photo: try photo(), aspect: .portrait, quality: .p1080)
        let generation = try await generation(id) { $0.localVideoName != nil }

        #expect(generation.status == .succeeded)
        #expect(generation.serverId == 900_001)
        #expect(generation.videoURL == remote)
        #expect(api.statusRequests == 3)
        #expect(api.createdTemplateIds == [template.id])
    }

    @Test func serverErrorFailsAndRetryStartsAgain() async throws {
        api.setStatuses([.success(.failed)])
        let id = try await service.create(template: template, photo: try photo(), aspect: .square, quality: .p720)
        let failed = try await generation(id) { $0.status == .failed }
        #expect(failed.failure?.kind == .server)

        api.setStatuses([.success(.succeeded(try makeRemoteVideo()))])
        try await service.retry(id: id)
        let retried = try await generation(id) { $0.localVideoName != nil }

        #expect(retried.status == .succeeded)
        #expect(retried.failure == nil)
        #expect(api.createdTemplateIds.count == 2)
    }

    private func generation(
        _ id: UUID,
        until condition: @escaping @Sendable (VideoGeneration) -> Bool
    ) async throws -> VideoGeneration {
        let stream = repository.observeGeneration(id: id)
        let result = await withTaskGroup(of: VideoGeneration?.self) { group in
            group.addTask {
                for await generation in stream {
                    if let generation, condition(generation) { return generation }
                }
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

    // Сервер «отдаёт» видео локальным файлом: URLSession умеет скачивать file://.
    private func makeRemoteVideo() throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(UUID().uuidString).mp4")
        try Data([0, 1, 2, 3]).write(to: url)
        return url
    }

    private func photo() throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 400, height: 300, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
