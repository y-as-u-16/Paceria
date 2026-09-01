import Foundation
@testable import Paceria

actor BookRepositorySpy: BookRepository {
    enum Failure: Error { case forced }

    private var books: [Book]
    private var shouldFail: Bool

    private(set) var savedBooks: [Book] = []
    private(set) var deletedIDs: [UUID] = []

    init(books: [Book] = [], shouldFail: Bool = false) {
        self.books = books
        self.shouldFail = shouldFail
    }

    func fetchAll() async throws -> [Book] {
        if shouldFail { throw Failure.forced }
        return books
    }

    func fetch(status: ReadingStatus) async throws -> [Book] {
        if shouldFail { throw Failure.forced }
        return books.filter { $0.status == status }
    }

    func fetch(id: UUID) async throws -> Book? {
        if shouldFail { throw Failure.forced }
        return books.first { $0.id == id }
    }

    func save(_ book: Book) async throws {
        if shouldFail { throw Failure.forced }
        savedBooks.append(book)
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        } else {
            books.append(book)
        }
    }

    func delete(id: UUID) async throws {
        if shouldFail { throw Failure.forced }
        deletedIDs.append(id)
        books.removeAll { $0.id == id }
    }

    func finishedCount(in interval: DateInterval) async throws -> Int {
        if shouldFail { throw Failure.forced }
        return books.filter { book in
            guard let finishedAt = book.finishedAt else { return false }
            return interval.containsExcludingEnd(finishedAt)
        }.count
    }

    func setShouldFail(_ value: Bool) { shouldFail = value }
}
