import Foundation

nonisolated protocol CacheManaging: Sendable {
    func size() async -> Int64
    func clear() async
}
