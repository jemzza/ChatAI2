import Photos

final class SystemPhotoLibraryAccess: PhotoLibraryAccess {
    func requestAccess() async -> Bool {
        switch await PHPhotoLibrary.requestAuthorization(for: .readWrite) {
            case .authorized, .limited: true
            default: false
        }
    }
}

final class SystemPhotoSaver: PhotoSaving {
    struct AccessDenied: Error {}
    
    func saveVideo(at fileURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw AccessDenied() }
        try await PHPhotoLibrary.shared().performChanges(Self.creationRequest(for: fileURL))
    }
    
    private nonisolated static func creationRequest(for fileURL: URL) -> @Sendable () -> Void {
        { _ = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: fileURL) }
    }
}
