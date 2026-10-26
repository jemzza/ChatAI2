import Foundation

nonisolated struct FileCacheManager: CacheManaging {
    let directories: [URL]
    
    static func standard() -> FileCacheManager {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return FileCacheManager(directories: ["Videos", "Thumbnails"].map {
            caches.appendingPathComponent($0, isDirectory: true)
        })
    }
    
    func size() async -> Int64 {
        await Task.detached(priority: .utility) { [directories] in
            directories.reduce(0) { $0 + Self.allocatedSize(of: $1) }
        }.value
    }
    
    func clear() async {
        await Task.detached(priority: .utility) { [directories] in
            for directory in directories {
                try? FileManager.default.removeItem(at: directory)
            }
        }.value
    }
    
    private static func allocatedSize(of directory: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: Array(keys)) else {
            return 0
        }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? 0)
        }
        return total
    }
}
