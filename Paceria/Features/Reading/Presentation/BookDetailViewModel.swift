import Foundation
import Observation

@MainActor
@Observable
final class BookDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(Book)
        case deleted
        case failed
    }

    private(set) var state: State = .loading

    private let bookID: UUID
    private let repository: any BookRepository
    private let finishBook: FinishBookUseCase
    private let now: @Sendable () -> Date

    init(
        bookID: UUID,
        repository: any BookRepository,
        finishBook: FinishBookUseCase,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.bookID = bookID
        self.repository = repository
        self.finishBook = finishBook
        self.now = now
    }

    var book: Book? {
        guard case .loaded(let book) = state else { return nil }
        return book
    }

    func load() async {
        state = .loading

        do {
            guard let book = try await repository.fetch(id: bookID) else {
                state = .failed
                return
            }
            state = .loaded(book)
        } catch {
            state = .failed
        }
    }

    /// 読了だけは UseCase を通す。status と finishedAt を別々に更新できると
    /// 過去の月次集計が壊れる（docs/03_DOMAIN_AND_DATA.md §9）。
    func changeStatus(to status: ReadingStatus) async {
        guard var book = book else { return }

        do {
            if status == .finished {
                state = .loaded(try await finishBook.execute(bookID: bookID))
                return
            }

            let timestamp = now()
            book.status = status
            book.updatedAt = timestamp
            if status == .reading, book.startedAt == nil {
                book.startedAt = timestamp
            }

            try await repository.save(book)
            state = .loaded(book)
        } catch {
            state = .failed
        }
    }

    func updateRating(_ rating: Int?) async {
        await update { $0.rating = rating }
    }

    func updateNote(_ note: String) async {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        await update { $0.note = trimmed.isEmpty ? nil : trimmed }
    }

    func delete() async {
        do {
            try await repository.delete(id: bookID)
            state = .deleted
        } catch {
            state = .failed
        }
    }

    private func update(_ mutate: (inout Book) -> Void) async {
        guard var book = book else { return }

        mutate(&book)
        book.updatedAt = now()

        do {
            try await repository.save(book)
            state = .loaded(book)
        } catch {
            state = .failed
        }
    }
}
