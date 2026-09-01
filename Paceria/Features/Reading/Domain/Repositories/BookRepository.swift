import Foundation

protocol BookRepository: Sendable {
    func fetchAll() async throws -> [Book]
    func fetch(status: ReadingStatus) async throws -> [Book]
    func fetch(id: UUID) async throws -> Book?
    func save(_ book: Book) async throws
    func delete(id: UUID) async throws
    func finishedCount(in interval: DateInterval) async throws -> Int
}
