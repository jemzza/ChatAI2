import Combine
import SwiftUI

final class GenerationViewModel: ObservableObject {
    enum Phase: Equatable {
        case loading
        case generating
        case ready(URL)
        case failed(ErrorKind)
        case missing
    }
    
    enum SaveResult: Equatable {
        case saved
        case failed
    }
    
    typealias Replace = (VideoGeneration, Data) async throws -> UUID
    
    @Published private(set) var generation: VideoGeneration?
    @Published private(set) var phase = Phase.loading
    @Published var isPlaying = false
    @Published private(set) var isSaving = false
    @Published var saveResult: SaveResult?
    @Published var shareURL: URL?
    @Published var toast: ToastMessage?
    
    var onReplaced: (UUID) -> Void = { _ in }
    
    let id: UUID
    private let repository: any VideoRepository
    private let media: any MediaStoring
    private let photoSaver: any PhotoSaving
    private let service: VideoGenerationService
    private let replace: Replace
    
    init(
        id: UUID,
        repository: any VideoRepository,
        media: any MediaStoring,
        photoSaver: any PhotoSaving,
        service: VideoGenerationService,
        replace: @escaping Replace
    ) {
        self.id = id
        self.repository = repository
        self.media = media
        self.photoSaver = photoSaver
        self.service = service
        self.replace = replace
    }
    
    var aspect: VideoAspect { generation?.aspect ?? .portrait }
    
    var isResult: Bool {
        if case .ready = phase { return true }
        return false
    }
    
    func observe() async {
        for await generation in repository.observeGeneration(id: id) {
            self.generation = generation
            let newPhase = Self.phase(for: generation, media: media)
            if newPhase != phase { phase = newPhase }
            if case .ready = newPhase, generation?.isViewed == false {
                await service.markViewed(id: id)
            }
        }
    }
    
    static func phase(for generation: VideoGeneration?, media: any MediaStoring) -> Phase {
        guard let generation else { return .missing }
        switch generation.status {
            case .creating, .generating:
                return .generating
            case .failed:
                return .failed(generation.failure?.kind ?? .unknown)
            case .succeeded:
                if let local = generation.localVideoName.flatMap(media.localVideoURL(named:)) { return .ready(local) }
                if let url = generation.videoURL { return .ready(url) }
                return .failed(.unknown)
        }
    }
    
    func togglePlayback() {
        isPlaying.toggle()
    }
    
    func retry() async {
        try? await service.retry(id: id)
    }
    
    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await photoSaver.saveVideo(at: try await localFile())
            saveResult = .saved
        } catch {
            saveResult = .failed
        }
    }
    
    func share() async {
        do {
            let file = try await localFile()
            shareURL = Self.shareableCopy(of: file, named: generation?.templateName ?? "") ?? file
        } catch {
            toast = ToastMessage(kind: .failure, text: "Couldn't load video")
        }
    }
    
    func replacePhoto(_ data: Data) async {
        guard let generation else { return }
        do {
            onReplaced(try await replace(generation, data))
        } catch {
            toast = ToastMessage(kind: .failure, text: "Upload failed")
        }
    }
    
    static func shareableCopy(of file: URL, named name: String) -> URL? {
        let base = name
            .components(separatedBy: CharacterSet(charactersIn: "/:\\").union(.whitespacesAndNewlines))
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Share", isDirectory: true)
        let target = directory
            .appendingPathComponent(base.isEmpty ? "Video" : base)
            .appendingPathExtension(file.pathExtension)
        do {
            try? FileManager.default.removeItem(at: directory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            do {
                try FileManager.default.linkItem(at: file, to: target)
            } catch {
                try FileManager.default.copyItem(at: file, to: target)
            }
            return target
        } catch {
            return nil
        }
    }
    
    private func localFile() async throws -> URL {
        guard let generation else { throw APIError(kind: .notFound) }
        if let local = generation.localVideoName.flatMap(media.localVideoURL(named:)) { return local }
        guard let remote = generation.videoURL,
              let local = media.localVideoURL(named: try await media.downloadVideo(from: remote))
        else { throw APIError(kind: .notFound) }
        return local
    }
}
