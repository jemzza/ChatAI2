import Foundation

nonisolated protocol VideoThumbnailing: Sendable {
    func thumbnail(for url: URL, maxPixelSize: Int) async -> Data?
}
