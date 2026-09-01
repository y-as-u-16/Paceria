import Foundation
import Testing
@testable import Paceria

@Suite("FinishBookUseCase")
struct FinishBookUseCaseTests {

    private let finishedAt = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeUseCase(_ repository: BookRepositorySpy) -> FinishBookUseCase {
        let now = finishedAt
        return FinishBookUseCase(repository: repository, now: { now })
    }

    @Test("status が finished になる")
    func setsStatusToFinished() async throws {
        let book = Book(title: "本", status: .reading)
        let repository = BookRepositorySpy(books: [book])

        let result = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(result.status == .finished)
    }

    @Test("finishedAt が設定される")
    func setsFinishedAt() async throws {
        let book = Book(title: "本", status: .reading)
        let repository = BookRepositorySpy(books: [book])

        let result = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(result.finishedAt == finishedAt)
    }

    @Test("startedAt が無ければ読了時刻で補う")
    func fillsMissingStartedAt() async throws {
        let book = Book(title: "本", status: .wantToRead, startedAt: nil)
        let repository = BookRepositorySpy(books: [book])

        let result = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(result.startedAt == finishedAt)
    }

    @Test("既存の startedAt は上書きしない")
    func keepsExistingStartedAt() async throws {
        let startedAt = finishedAt.addingTimeInterval(-86400 * 30)
        let book = Book(title: "本", status: .reading, startedAt: startedAt)
        let repository = BookRepositorySpy(books: [book])

        let result = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(result.startedAt == startedAt)
    }

    @Test("保存される")
    func persistsBook() async throws {
        let book = Book(title: "本", status: .reading)
        let repository = BookRepositorySpy(books: [book])

        _ = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(await repository.savedBooks.count == 1)
        #expect(await repository.savedBooks.first?.finishedAt == finishedAt)
    }

    @Test("存在しない本は notFound")
    func throwsWhenBookMissing() async {
        let useCase = makeUseCase(BookRepositorySpy())

        await #expect(throws: AppError.notFound) {
            try await useCase.execute(bookID: UUID())
        }
    }

    @Test("読み返しでは finishedAt が最新に更新される")
    func rereadUpdatesFinishedAt() async throws {
        let previous = finishedAt.addingTimeInterval(-86400 * 60)
        let book = Book(title: "本", status: .finished, finishedAt: previous)
        let repository = BookRepositorySpy(books: [book])

        let result = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(result.finishedAt == finishedAt)
    }

    @Test("updatedAt も読了時刻になる")
    func updatesTimestamp() async throws {
        let book = Book(title: "本", status: .reading, updatedAt: finishedAt.addingTimeInterval(-1000))
        let repository = BookRepositorySpy(books: [book])

        let result = try await makeUseCase(repository).execute(bookID: book.id)

        #expect(result.updatedAt == finishedAt)
    }
}
