import Foundation
import GRDB

nonisolated final class GRDBVideoRepository: VideoRepository {
    private let writer: any DatabaseWriter
    private let observationQueue = DispatchQueue(label: "GRDBVideoRepository.observation")
    
    init(database: AppDatabase) {
        writer = database.writer
    }
    
    func observeGenerations() -> AsyncStream<[VideoGeneration]> {
        writer.observe(on: observationQueue) { db in
            try VideoGenerationRecord
                .order(VideoGenerationRecord.Columns.createdAt.desc, Column.rowID.desc)
                .fetchAll(db)
                .map(\.generation)
        }
    }
    
    func observeGeneration(id: UUID) -> AsyncStream<VideoGeneration?> {
        writer.observe(on: observationQueue) { db in
            try VideoGenerationRecord.fetchOne(db, key: id)?.generation
        }
    }
    
    func generation(id: UUID) async throws -> VideoGeneration {
        let record = try await writer.read { db in try VideoGenerationRecord.fetchOne(db, key: id) }
        guard let record else { throw RepositoryError.generationNotFound(id) }
        return record.generation
    }
    
    func activeGenerations() async throws -> [VideoGeneration] {
        try await writer.read { db in
            try VideoGenerationRecord
                .filter([VideoGenerationStatus.creating.rawValue, VideoGenerationStatus.generating.rawValue]
                    .contains(VideoGenerationRecord.Columns.status))
                .order(VideoGenerationRecord.Columns.createdAt)
                .fetchAll(db)
                .map(\.generation)
        }
    }
    
    func insert(_ generation: VideoGeneration) async throws {
        try await writer.write { db in
            try VideoGenerationRecord(generation).insert(db)
        }
    }
    
    func update(_ generation: VideoGeneration) async throws {
        do {
            try await writer.write { db in
                try VideoGenerationRecord(generation).update(db)
            }
        } catch is RecordError {
            throw RepositoryError.generationNotFound(generation.id)
        }
    }
    
    func delete(id: UUID) async throws {
        _ = try await writer.write { db in
            try VideoGenerationRecord.deleteOne(db, key: id)
        }
    }
}
