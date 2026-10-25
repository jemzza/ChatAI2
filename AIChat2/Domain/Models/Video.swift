import Foundation

nonisolated struct VideoTemplate: Identifiable, Hashable, Sendable {
    let id: Int64
    let name: String
    let category: String
    let previewURL: URL?
    let qualities: [VideoQuality]
    let duration: Int?
}

nonisolated enum VideoAspect: String, CaseIterable, Hashable, Sendable {
    case landscape = "16:9"
    case portrait = "9:16"
    case square = "1:1"
    
    var ratio: Double {
        switch self {
            case .landscape: 16.0 / 9.0
            case .portrait: 9.0 / 16.0
            case .square: 1
        }
    }
}

nonisolated enum VideoQuality: String, CaseIterable, Hashable, Sendable {
    case p360 = "360p"
    case p540 = "540p"
    case p720 = "720p"
    case p1080 = "1080p"
}

nonisolated enum VideoServerStatus: Hashable, Sendable {
    case generating
    case succeeded(URL)
    case failed
}

nonisolated enum VideoGenerationStatus: String, Hashable, Sendable {
    case creating
    case generating
    case succeeded
    case failed
    
    var isActive: Bool { self == .creating || self == .generating }
}

nonisolated struct VideoGeneration: Identifiable, Hashable, Sendable {
    let id: UUID
    let templateId: Int64
    let templateName: String
    let aspect: VideoAspect
    let quality: VideoQuality
    let sourceImageName: String
    var status: VideoGenerationStatus
    var serverId: Int64?
    var videoURL: URL?
    var localVideoName: String?
    var failure: MessageFailure?
    var isViewed: Bool
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        templateId: Int64,
        templateName: String,
        aspect: VideoAspect,
        quality: VideoQuality,
        sourceImageName: String,
        status: VideoGenerationStatus = .creating,
        serverId: Int64? = nil,
        videoURL: URL? = nil,
        localVideoName: String? = nil,
        failure: MessageFailure? = nil,
        isViewed: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.templateId = templateId
        self.templateName = templateName
        self.aspect = aspect
        self.quality = quality
        self.sourceImageName = sourceImageName
        self.status = status
        self.serverId = serverId
        self.videoURL = videoURL
        self.localVideoName = localVideoName
        self.failure = failure
        self.isViewed = isViewed
        self.createdAt = createdAt
    }
}
