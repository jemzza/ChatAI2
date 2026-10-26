import Foundation
import Testing
@testable import AIChat2

struct VideoThumbnailServiceTests {
    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    // Одна загрузка за раз: вторая ждёт в очереди, её отменяют (карточка ушла с экрана) —
    // она не должна ничего грузить, а следующий запрос должен получить кадр.
    @Test func cancelledRequestLeavesQueueWithoutLoading() async throws {
        let videos = try (0..<3).map(makeVideo)
        let thumbnails = directory.appendingPathComponent("thumbs")
        let service = VideoThumbnailService(directory: thumbnails, maxConcurrentLoads: 1)

        let first = Task { await service.thumbnail(for: videos[0], maxPixelSize: 120) }
        try await Task.sleep(for: .milliseconds(20))
        let skipped = Task { await service.thumbnail(for: videos[1], maxPixelSize: 120) }
        try await Task.sleep(for: .milliseconds(20))
        skipped.cancel()
        let last = Task { await service.thumbnail(for: videos[2], maxPixelSize: 120) }

        #expect(await skipped.value == nil)
        #expect(await first.value != nil)
        #expect(await last.value != nil)
        let cached = try FileManager.default.contentsOfDirectory(atPath: thumbnails.path)
        #expect(cached.count == 2)
    }

    private func makeVideo(_ index: Int) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(index).mp4")
        let jpeg = try #require(SolidImage.jpeg(hue: Double(index) / 3))
        try FakeVideoRenderer.render(jpeg: jpeg, to: url, seconds: 1)
        return url
    }
}
