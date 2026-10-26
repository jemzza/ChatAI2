import AVFoundation
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

actor VideoThumbnailService: VideoThumbnailing {
    private final class Job {
        let task: Task<Data?, Never>
        var waiters = 0
        var abandoned = 0

        init(task: Task<Data?, Never>) {
            self.task = task
        }
    }

    private let directory: URL
    private let memory = NSCache<NSString, NSData>()
    private let limiter: LoadLimiter
    private var jobs: [String: Job] = [:]

    init(directory: URL, maxConcurrentLoads: Int = 4) {
        self.directory = directory
        limiter = LoadLimiter(limit: maxConcurrentLoads)
        memory.countLimit = 200
    }

    static func standard() -> VideoThumbnailService {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return VideoThumbnailService(directory: caches.appendingPathComponent("Thumbnails", isDirectory: true))
    }

    func thumbnail(for url: URL, maxPixelSize: Int) async -> Data? {
        let key = Self.key(url: url, size: maxPixelSize)
        if let cached = memory.object(forKey: key as NSString) { return cached as Data }

        let job: Job
        if let existing = jobs[key], !existing.task.isCancelled {
            job = existing
        } else {
            job = Job(task: makeTask(url: url, maxPixelSize: maxPixelSize, key: key))
            jobs[key] = job
        }
        job.waiters += 1

        let data = await withTaskCancellationHandler {
            await job.task.value
        } onCancel: {
            Task { await self.abandon(job) }
        }
        if jobs[key] === job { jobs[key] = nil }
        if let data { memory.setObject(data as NSData, forKey: key as NSString) }
        return Task.isCancelled ? nil : data
    }

    private func abandon(_ job: Job) {
        job.abandoned += 1
        if job.abandoned >= job.waiters { job.task.cancel() }
    }

    private func makeTask(url: URL, maxPixelSize: Int, key: String) -> Task<Data?, Never> {
        let file = directory.appendingPathComponent("\(key).jpg", isDirectory: false)
        let limiter = limiter
        return Task.detached(priority: .utility) {
            if let data = try? Data(contentsOf: file) { return data }
            guard await limiter.acquire() else { return nil }
            let data = await Self.firstFrame(of: url, maxPixelSize: maxPixelSize)
            await limiter.release()
            guard let data else { return nil }
            try? FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: file, options: .atomic)
            return data
        }
    }

    static func firstFrame(of url: URL, maxPixelSize: Int) async -> Data? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize)
        let image = await withTaskCancellationHandler {
            try? await generator.image(at: .zero).image
        } onCancel: {
            generator.cancelAllCGImageGeneration()
        }
        guard let image, !Task.isCancelled else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    private static func key(url: URL, size: Int) -> String {
        let digest = SHA256.hash(data: Data("\(url.absoluteString)#\(size)".utf8))
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }
}

private actor LoadLimiter {
    private let limit: Int
    private var running = 0
    private var queue: [(id: UUID, continuation: CheckedContinuation<Bool, Never>)] = []

    init(limit: Int) {
        self.limit = limit
    }

    func acquire() async -> Bool {
        guard !Task.isCancelled else { return false }
        if running < limit {
            running += 1
            return true
        }
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { queue.append((id, $0)) }
        } onCancel: {
            Task { await self.cancel(id) }
        }
    }

    func release() {
        if let next = queue.popLast() {
            next.continuation.resume(returning: true)
        } else {
            running -= 1
        }
    }

    private func cancel(_ id: UUID) {
        guard let index = queue.firstIndex(where: { $0.id == id }) else { return }
        queue.remove(at: index).continuation.resume(returning: false)
    }
}
