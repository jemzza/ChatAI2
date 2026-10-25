import Foundation
import GRDB

nonisolated struct FolderRecord: Codable, Hashable, Sendable {
    static let databaseTableName = "folder"
    
    var id: UUID
    var name: String
    var createdAt: Date
    
    enum Columns {
        static let name = Column(CodingKeys.name)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}

nonisolated extension FolderRecord: FetchableRecord, PersistableRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy {
        .timeIntervalSinceReferenceDate
    }
    
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy {
        .timeIntervalSinceReferenceDate
    }
}

nonisolated extension FolderRecord {
    init(_ folder: Folder) {
        id = folder.id
        name = folder.name
        createdAt = folder.createdAt
    }
    
    var folder: Folder {
        Folder(id: id, name: name, createdAt: createdAt)
    }
}
