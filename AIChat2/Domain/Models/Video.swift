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
