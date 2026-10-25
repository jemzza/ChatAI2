import Foundation

nonisolated protocol VideoRepository: Sendable {
    func observeGenerations() -> AsyncStream<[VideoGeneration]>
    func observeGeneration(id: UUID) -> AsyncStream<VideoGeneration?>
    func generation(id: UUID) async throws -> VideoGeneration
    func activeGenerations() async throws -> [VideoGeneration]
    func insert(_ generation: VideoGeneration) async throws
    func update(_ generation: VideoGeneration) async throws
    func delete(id: UUID) async throws
}
