import Foundation

nonisolated protocol MediaStoring: Sendable {
    func saveSourceImage(_ data: Data, aspect: VideoAspect) async -> String?
    func sourceImage(named name: String) -> Data?
    func sourceImageURL(named name: String) -> URL
    func downloadVideo(from url: URL) async throws -> String
    func localVideoURL(named name: String) -> URL?
    func deleteFiles(sourceImageName: String?, videoName: String?)
}
