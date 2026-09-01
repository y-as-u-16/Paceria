import Foundation
import SwiftData

@ModelActor
actor SwiftDataBookRepository: BookRepository {

    func fetchAll() async throws -> [Book] {
        try modelContext.fetch(sortedDescriptor()).map(BookMapper.toDomain)
    }

    func fetch(status: ReadingStatus) async throws -> [Book] {
        let rawValue = status.rawValue
        var descriptor = sortedDescriptor()
        descriptor.predicate = #Predicate { $0.statusRawValue == rawValue }

        return try modelContext.fetch(descriptor).map(BookMapper.toDomain)
    }

    func fetch(id: UUID) async throws -> Book? {
        try record(id: id).map(BookMapper.toDomain)
    }

    func save(_ book: Book) async throws {
        if let existing = try record(id: book.id) {
            BookMapper.apply(book, to: existing)
        } else {
            modelContext.insert(BookMapper.toRecord(book))
        }
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        guard let record = try record(id: id) else { throw AppError.notFound }

        modelContext.delete(record)
        try modelContext.save()
    }

    /// 集計の基準は finishedAt であって status ではない
    /// （docs/03_DOMAIN_AND_DATA.md §9）。
    func finishedCount(in interval: DateInterval) async throws -> Int {
        let start = interval.start
        let end = interval.end

        return try modelContext.fetchCount(
            FetchDescriptor<BookRecord>(
                // #Predicate は単一式のみ。nil の finishedAt は比較が成立せず除外される。
                predicate: #Predicate { $0.finishedAt.flatMap { $0 >= start && $0 < end } ?? false }
            )
        )
    }

    private func sortedDescriptor() -> FetchDescriptor<BookRecord> {
        FetchDescriptor<BookRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
    }

    private func record(id: UUID) throws -> BookRecord? {
        var descriptor = FetchDescriptor<BookRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }
}
