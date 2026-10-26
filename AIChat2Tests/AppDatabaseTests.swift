import Foundation
import GRDB
import Testing
@testable import AIChat2

struct AppDatabaseTests {
    // База от первой версии приложения: те же имена миграций, но другая схема
    // (у папок обязательный position) и миграции, о которых текущая версия не знает.
    @Test func databaseFromPreviousVersionIsRecreated() async throws {
        let queue = try DatabaseQueue()
        var legacy = DatabaseMigrator()
        legacy.registerMigration("v1") { db in
            try db.create(table: "chat") { t in
                t.primaryKey("id", .blob)
                t.column("title", .text).notNull()
            }
        }
        legacy.registerMigration("v2") { db in
            try db.create(table: "folder") { t in
                t.primaryKey("id", .blob)
                t.column("name", .text).notNull()
                t.column("position", .integer).notNull()
                t.column("createdAt", .double).notNull()
            }
        }
        legacy.registerMigration("v5") { _ in }
        try legacy.migrate(queue)

        let repository = GRDBChatRepository(database: try AppDatabase(queue))
        let folder = Folder(id: UUID(), name: "Work", createdAt: Date())
        try await repository.createFolder(folder)

        let names = try await queue.read { db in try String.fetchAll(db, sql: "SELECT name FROM folder") }
        #expect(names == ["Work"])
    }
}
