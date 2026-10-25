import Foundation
import GRDB

nonisolated struct AppDatabase: Sendable {
    let writer: any DatabaseWriter
    
    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }
    
    static func onDisk(fileName: String = "AIChat.sqlite") throws -> AppDatabase {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let url = folder.appendingPathComponent(fileName, isDirectory: false)
        return try AppDatabase(DatabasePool(path: url.path, configuration: configuration))
    }
    
    static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue(configuration: configuration))
    }
    
    private static var configuration: Configuration {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        return configuration
    }
    
    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: FolderRecord.databaseTableName) { t in
                t.primaryKey("id", .blob)
                t.column("name", .text).notNull()
                t.column("createdAt", .double).notNull()
            }
            try db.create(table: ChatRecord.databaseTableName) { t in
                t.primaryKey("id", .blob)
                t.column("title", .text).notNull()
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull().indexed()
                t.column("folderId", .blob)
                    .references(FolderRecord.databaseTableName, onDelete: .setNull)
                    .indexed()
                t.column("pinnedAt", .double)
            }
            try db.create(table: MessageRecord.databaseTableName) { t in
                t.primaryKey("id", .blob)
                t.belongsTo(ChatRecord.databaseTableName, onDelete: .cascade, indexed: false).notNull()
                t.column("role", .text).notNull()
                t.column("text", .text).notNull()
                t.column("status", .text).notNull().indexed()
                t.column("failureKind", .text)
                t.column("failureRetryAt", .double)
                t.column("createdAt", .double).notNull()
            }
            try db.create(
                index: "message_on_chatId_createdAt",
                on: MessageRecord.databaseTableName,
                columns: ["chatId", "createdAt"]
            )
        }
        return migrator
    }
}

nonisolated extension DatabaseWriter {
    func observe<Value: Equatable & Sendable>(
        on queue: DispatchQueue,
        _ fetch: @escaping @Sendable (Database) throws -> Value
    ) -> AsyncStream<Value> {
        let observation = ValueObservation.trackingConstantRegion(fetch).removeDuplicates()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let cancellable = observation.start(
                in: self,
                scheduling: .async(onQueue: queue),
                onError: { _ in continuation.finish() },
                onChange: { continuation.yield($0) }
            )
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }
}

nonisolated extension Date {
    var databaseTimestamp: Double { timeIntervalSinceReferenceDate }
}
