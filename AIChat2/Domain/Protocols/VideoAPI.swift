import Foundation

nonisolated protocol VideoAPI: Sendable {
    func templates() async throws -> [VideoTemplate]
    func createVideo(templateId: Int64, imageJPEG: Data, quality: VideoQuality, duration: Int?) async throws -> Int64
    func status(serverId: Int64) async throws -> VideoServerStatus
}
