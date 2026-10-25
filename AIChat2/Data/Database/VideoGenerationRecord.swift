import Foundation
import GRDB

nonisolated struct VideoGenerationRecord: Codable, Hashable, Sendable {
    static let databaseTableName = "videoGeneration"
    
    var id: UUID
    var templateId: Int64
    var templateName: String
    var aspect: String
    var quality: String
    var sourceImageName: String
    var status: String
    var serverId: Int64?
    var videoURL: String?
    var localVideoName: String?
    var failureKind: String?
    var isViewed: Bool
    var createdAt: Date
    
    enum Columns {
        static let status = Column(CodingKeys.status)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}

nonisolated extension VideoGenerationRecord: FetchableRecord, PersistableRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy {
        .timeIntervalSinceReferenceDate
    }
    
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy {
        .timeIntervalSinceReferenceDate
    }
}

nonisolated extension VideoGenerationRecord {
    init(_ generation: VideoGeneration) {
        id = generation.id
        templateId = generation.templateId
        templateName = generation.templateName
        aspect = generation.aspect.rawValue
        quality = generation.quality.rawValue
        sourceImageName = generation.sourceImageName
        status = generation.status.rawValue
        serverId = generation.serverId
        videoURL = generation.videoURL?.absoluteString
        localVideoName = generation.localVideoName
        failureKind = generation.failure?.kind.rawValue
        isViewed = generation.isViewed
        createdAt = generation.createdAt
    }
    
    var generation: VideoGeneration {
        VideoGeneration(
            id: id,
            templateId: templateId,
            templateName: templateName,
            aspect: VideoAspect(rawValue: aspect) ?? .landscape,
            quality: VideoQuality(rawValue: quality) ?? .p1080,
            sourceImageName: sourceImageName,
            status: VideoGenerationStatus(rawValue: status) ?? .failed,
            serverId: serverId,
            videoURL: videoURL.flatMap(URL.init(string:)),
            localVideoName: localVideoName,
            failure: failureKind.map { MessageFailure(kind: ErrorKind(rawValue: $0) ?? .unknown) },
            isViewed: isViewed,
            createdAt: createdAt
        )
    }
}
