import Foundation
import SwiftData

@ModelActor
actor SwiftDataMovementRepository: MovementRepository {

    func fetch(in interval: DateInterval) async throws -> [MovementSession] {
        try modelContext.fetch(descriptor(for: interval)).map(MovementMapper.toDomain)
    }

    func save(_ session: MovementSession) async throws {
        if let existing = try record(id: session.id) {
            MovementMapper.apply(session, to: existing)
        } else {
            modelContext.insert(MovementMapper.toRecord(session))
        }
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        guard let record = try record(id: id) else { throw AppError.notFound }

        modelContext.delete(record)
        try modelContext.save()
    }

    func count(in interval: DateInterval) async throws -> Int {
        try modelContext.fetchCount(descriptor(for: interval))
    }

    /// 終端を含めると隣接する期間で二重カウントされる。
    private func descriptor(for interval: DateInterval) -> FetchDescriptor<MovementRecord> {
        let start = interval.start
        let end = interval.end

        return FetchDescriptor<MovementRecord>(
            predicate: #Predicate { $0.performedAt >= start && $0.performedAt < end },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
    }

    private func record(id: UUID) throws -> MovementRecord? {
        var descriptor = FetchDescriptor<MovementRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }
}
