import Foundation

protocol PhotoLibraryAccess: AnyObject {
    func requestAccess() async -> Bool
}

protocol PhotoSaving: AnyObject {
    func saveVideo(at fileURL: URL) async throws
}
