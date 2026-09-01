import Foundation
import Testing
@testable import Paceria

@Suite("LibraryViewModel")
@MainActor
struct LibraryViewModelTests {

    @Test("初期状態は loading")
    func initialStateIsLoading() {
        #expect(LibraryViewModel(repository: BookRepositorySpy()).state == .loading)
    }

    @Test("本が無ければ empty")
    func emptyWhenNoBooks() async {
        let viewModel = LibraryViewModel(repository: BookRepositorySpy())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("status ごとに分類される")
    func groupsByStatus() async {
        let reading = Book(title: "読書中", status: .reading)
        let finished = Book(title: "読了", status: .finished)
        let viewModel = LibraryViewModel(repository: BookRepositorySpy(books: [reading, finished]))

        await viewModel.load()

        #expect(viewModel.books(for: .reading).map(\.id) == [reading.id])
        #expect(viewModel.books(for: .finished).map(\.id) == [finished.id])
        #expect(viewModel.books(for: .paused).isEmpty)
    }

    @Test("失敗したら failed")
    func failedWhenRepositoryThrows() async {
        let viewModel = LibraryViewModel(repository: BookRepositorySpy(shouldFail: true))

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test("削除すると一覧から消える")
    func deleteRemovesBook() async {
        let book = Book(title: "本", status: .reading)
        let repository = BookRepositorySpy(books: [book])
        let viewModel = LibraryViewModel(repository: repository)
        await viewModel.load()

        await viewModel.delete(id: book.id)

        #expect(viewModel.state == .empty)
        #expect(await repository.deletedIDs == [book.id])
    }
}

@Suite("AddBookViewModel")
@MainActor
struct AddBookViewModelTests {

    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeViewModel(_ repository: BookRepositorySpy) -> AddBookViewModel {
        let now = referenceDate
        return AddBookViewModel(repository: repository, now: { now })
    }

    @Test("タイトルが空なら保存できない")
    func cannotSaveWithoutTitle() async {
        let repository = BookRepositorySpy()
        let viewModel = makeViewModel(repository)

        #expect(!viewModel.canSave)
        #expect(!(await viewModel.save()))
        #expect(viewModel.error == .invalid(.emptyTitle))
        #expect(await repository.savedBooks.isEmpty)
    }

    @Test("空白だけのタイトルも拒否する")
    func rejectsWhitespaceOnlyTitle() async {
        let viewModel = makeViewModel(BookRepositorySpy())
        viewModel.title = "   "

        #expect(!viewModel.canSave)
        #expect(!(await viewModel.save()))
    }

    @Test("タイトルだけで保存できる")
    func savesWithTitleOnly() async {
        let repository = BookRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.title = "本"

        #expect(await viewModel.save())
        #expect(await repository.savedBooks.first?.author == nil)
    }

    @Test("前後の空白を取り除く")
    func trimsInput() async {
        let repository = BookRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.title = "  銀河鉄道の夜  "
        viewModel.author = "  宮沢賢治  "

        _ = await viewModel.save()
        let saved = await repository.savedBooks.first

        #expect(saved?.title == "銀河鉄道の夜")
        #expect(saved?.author == "宮沢賢治")
    }

    @Test("読書中で登録すると startedAt が入る")
    func setsStartedAtWhenReading() async {
        let repository = BookRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.title = "本"
        viewModel.status = .reading

        _ = await viewModel.save()

        #expect(await repository.savedBooks.first?.startedAt == referenceDate)
    }

    @Test("読みたいで登録すると startedAt は入らない")
    func noStartedAtWhenWantToRead() async {
        let repository = BookRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.title = "本"
        viewModel.status = .wantToRead

        _ = await viewModel.save()

        #expect(await repository.savedBooks.first?.startedAt == nil)
    }

    @Test("保存に失敗したらエラーを立てる")
    func reportsSaveFailure() async {
        let viewModel = makeViewModel(BookRepositorySpy(shouldFail: true))
        viewModel.title = "本"

        #expect(!(await viewModel.save()))
        #expect(viewModel.error == .saveFailed)
    }
}

@Suite("BookDetailViewModel")
@MainActor
struct BookDetailViewModelTests {

    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeViewModel(_ repository: BookRepositorySpy, bookID: UUID) -> BookDetailViewModel {
        let now = referenceDate
        return BookDetailViewModel(
            bookID: bookID,
            repository: repository,
            finishBook: FinishBookUseCase(repository: repository, now: { now }),
            now: { now }
        )
    }

    @Test("読み込むと loaded になる")
    func loadsBook() async {
        let book = Book(title: "本")
        let viewModel = makeViewModel(BookRepositorySpy(books: [book]), bookID: book.id)

        await viewModel.load()

        #expect(viewModel.book?.id == book.id)
    }

    @Test("存在しない本は failed")
    func failedWhenMissing() async {
        let viewModel = makeViewModel(BookRepositorySpy(), bookID: UUID())

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test("読了にすると finishedAt が入る")
    func finishingSetsFinishedAt() async {
        let book = Book(title: "本", status: .reading)
        let viewModel = makeViewModel(BookRepositorySpy(books: [book]), bookID: book.id)
        await viewModel.load()

        await viewModel.changeStatus(to: .finished)

        #expect(viewModel.book?.status == .finished)
        #expect(viewModel.book?.finishedAt == referenceDate)
    }

    @Test("読了以外の status 変更では finishedAt を触らない")
    func nonFinishStatusKeepsFinishedAt() async {
        let previous = referenceDate.addingTimeInterval(-86400)
        let book = Book(title: "本", status: .finished, finishedAt: previous)
        let viewModel = makeViewModel(BookRepositorySpy(books: [book]), bookID: book.id)
        await viewModel.load()

        await viewModel.changeStatus(to: .reading)

        #expect(viewModel.book?.status == .reading)
        #expect(viewModel.book?.finishedAt == previous)
    }

    @Test("読書中にすると startedAt が入る")
    func readingSetsStartedAt() async {
        let book = Book(title: "本", status: .wantToRead)
        let viewModel = makeViewModel(BookRepositorySpy(books: [book]), bookID: book.id)
        await viewModel.load()

        await viewModel.changeStatus(to: .reading)

        #expect(viewModel.book?.startedAt == referenceDate)
    }

    @Test("評価を設定・解除できる")
    func updatesRating() async {
        let book = Book(title: "本")
        let viewModel = makeViewModel(BookRepositorySpy(books: [book]), bookID: book.id)
        await viewModel.load()

        await viewModel.updateRating(4)
        #expect(viewModel.book?.rating == 4)

        await viewModel.updateRating(nil)
        #expect(viewModel.book?.rating == nil)
    }

    @Test("空白だけのメモは nil にする")
    func blankNoteBecomesNil() async {
        let book = Book(title: "本")
        let viewModel = makeViewModel(BookRepositorySpy(books: [book]), bookID: book.id)
        await viewModel.load()

        await viewModel.updateNote("   ")

        #expect(viewModel.book?.note == nil)
    }

    @Test("削除すると deleted になる")
    func deleteSetsDeletedState() async {
        let book = Book(title: "本")
        let repository = BookRepositorySpy(books: [book])
        let viewModel = makeViewModel(repository, bookID: book.id)
        await viewModel.load()

        await viewModel.delete()

        #expect(viewModel.state == .deleted)
        #expect(await repository.deletedIDs == [book.id])
    }

    @Test("削除に失敗したら failed")
    func deleteFailureSetsFailed() async {
        let book = Book(title: "本")
        let repository = BookRepositorySpy(books: [book])
        let viewModel = makeViewModel(repository, bookID: book.id)
        await viewModel.load()

        await repository.setShouldFail(true)
        await viewModel.delete()

        #expect(viewModel.state == .failed)
    }
}
