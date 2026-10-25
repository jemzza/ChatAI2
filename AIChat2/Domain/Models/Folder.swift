import Foundation

nonisolated struct Folder: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    let createdAt: Date
}
