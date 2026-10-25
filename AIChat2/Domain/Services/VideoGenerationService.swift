import Foundation

final class VideoGenerationService {
    struct Configuration: Sendable {
        var pollIntervals: [Duration] = [.seconds(3), .seconds(5), .seconds(10)]
        var maxPolls = 90
    }

    enum CreateError: Error {
        case invalidPhoto
    }

    private let repository: any VideoRepository
    private let api: any VideoAPI
    private let media: any MediaStoring
    private let connectivity: any ConnectivityMonitoring
    private let backgroundTasks: (any BackgroundTaskScheduling)?
    private let configuration: Configuration
    private let now: () -> Date

    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(
        repository: any VideoRepository,
        api: any VideoAPI,
        media: any MediaStoring,
        connectivity: any ConnectivityMonitoring,
        backgroundTasks: (any BackgroundTaskScheduling)? = nil,
        configuration: Configuration = Configuration(),
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.api = api
        self.media = media
        self.connectivity = connectivity
        self.backgroundTasks = backgroundTasks
        self.configuration = configuration
        self.now = now
    }

    func run() async {
        for await isOnline in connectivity.updates() where isOnline {
            await resume()
        }
    }

    func appDidBecomeActive() {
        Task { await resume() }
    }

    func resume() async {
        guard connectivity.isOnline, let active = try? await repository.activeGenerations() else { return }
        for generation in active {
            start(generation.id)
        }
    }

    func create(template: VideoTemplate, photo: Data, aspect: VideoAspect, quality: VideoQuality) async throws -> UUID {
        guard let imageName = await media.saveSourceImage(photo, aspect: aspect) else {
            throw CreateError.invalidPhoto
        }
        let generation = VideoGeneration(
            templateId: template.id,
            templateName: template.name,
            aspect: aspect,
            quality: quality,
            sourceImageName: imageName,
            createdAt: now()
        )
        do {
            try await repository.insert(generation)
        } catch {
            media.deleteFiles(sourceImageName: imageName, videoName: nil)
            throw error
        }
        start(generation.id)
        return generation.id
    }

    func retry(id: UUID) async throws {
        var generation = try await repository.generation(id: id)
        guard generation.status == .failed, tasks[id] == nil else { return }
        generation.status = .creating
        generation.serverId = nil
        generation.videoURL = nil
        generation.failure = nil
        try await repository.update(generation)
        start(id)
    }

    func markViewed(id: UUID) async {
        guard var generation = try? await repository.generation(id: id), !generation.isViewed else { return }
        generation.isViewed = true
        try? await repository.update(generation)
    }

    func delete(id: UUID) async throws {
        tasks.removeValue(forKey: id)?.cancel()
        let generation = try? await repository.generation(id: id)
        try await repository.delete(id: id)
        media.deleteFiles(sourceImageName: generation?.sourceImageName, videoName: generation?.localVideoName)
    }

    private func start(_ id: UUID) {
        guard tasks[id] == nil else { return }
        tasks[id] = Task { [weak self] in
            await self?.process(id)
            self?.tasks[id] = nil
        }
    }

    private func process(_ id: UUID) async {
        let backgroundToken = backgroundTasks?.beginTask { [weak self] in
            self?.tasks[id]?.cancel()
        }
        defer {
            if let backgroundToken { backgroundTasks?.endTask(backgroundToken) }
        }
        do {
            var generation = try await repository.generation(id: id)
            if generation.status == .creating {
                generation = try await submit(generation)
            }
            if generation.status == .generating {
                generation = try await poll(generation)
            }
            if generation.status == .succeeded {
                await download(generation)
            }
        } catch is CancellationError {
        } catch let error as APIError where error.kind == .offline {
        } catch RepositoryError.generationNotFound {
        } catch {
            await markFailed(id, error: error)
        }
    }

    private func submit(_ generation: VideoGeneration) async throws -> VideoGeneration {
        guard let image = media.sourceImage(named: generation.sourceImageName) else {
            throw APIError(kind: .unknown)
        }
        let serverId = try await api.createVideo(
            templateId: generation.templateId,
            imageJPEG: image,
            quality: generation.quality,
            duration: nil
        )
        var updated = try await repository.generation(id: generation.id)
        updated.serverId = serverId
        updated.status = .generating
        try await repository.update(updated)
        return updated
    }

    private func poll(_ generation: VideoGeneration) async throws -> VideoGeneration {
        guard let serverId = generation.serverId else { throw APIError(kind: .unknown) }
        let intervals = configuration.pollIntervals
        for attempt in 0..<configuration.maxPolls {
            switch try await api.status(serverId: serverId) {
                case let .succeeded(url):
                    var updated = try await repository.generation(id: generation.id)
                    updated.status = .succeeded
                    updated.videoURL = url
                    try await repository.update(updated)
                    return updated
                case .failed:
                    throw APIError(kind: .server)
                case .generating:
                    try await Task.sleep(for: intervals[min(attempt, intervals.count - 1)])
            }
        }
        throw APIError(kind: .server)
    }

    private func download(_ generation: VideoGeneration) async {
        guard generation.localVideoName == nil,
              let url = generation.videoURL,
              let name = try? await media.downloadVideo(from: url)
        else { return }
        guard var updated = try? await repository.generation(id: generation.id) else {
            media.deleteFiles(sourceImageName: nil, videoName: name)
            return
        }
        updated.localVideoName = name
        try? await repository.update(updated)
    }

    private func markFailed(_ id: UUID, error: any Error) async {
        guard var generation = try? await repository.generation(id: id) else { return }
        let kind = (error as? APIError)?.kind ?? .unknown
        generation.failure = MessageFailure(kind: kind == .notFound ? .server : kind)
        generation.status = .failed
        try? await repository.update(generation)
    }
}
