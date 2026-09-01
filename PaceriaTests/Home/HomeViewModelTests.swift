import Foundation
import Testing
@testable import Paceria

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()

    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 12))!
    }

    private func makeViewModel(
        books: [Book] = [],
        movements: [MovementSession] = [],
        shouldFail: Bool = false
    ) -> HomeViewModel {
        let bookRepository = BookRepositorySpy(books: books, shouldFail: shouldFail)
        let movementRepository = MovementRepositorySpy(sessions: movements, shouldFail: shouldFail)
        let now = referenceDate

        return HomeViewModel(
            getHomeSummary: GetHomeSummaryUseCase(
                goalRepository: GoalRepositoryStub(),
                bookRepository: bookRepository,
                movementRepository: movementRepository,
                calculateProgress: CalculateGoalProgressUseCase(
                    bookRepository: bookRepository,
                    movementRepository: movementRepository,
                    calendar: calendar
                ),
                calendar: calendar
            ),
            now: { now }
        )
    }

    @Test("初期状態は loading")
    func initialStateIsLoading() {
        #expect(makeViewModel().state == .loading)
    }

    @Test("記録が無くても loaded になる")
    func loadsWithNoRecords() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        #expect(viewModel.summary?.reading.current == 0)
        #expect(viewModel.summary?.recentWins.isEmpty == true)
    }

    @Test("記録があれば進捗に反映される")
    func reflectsRecords() async {
        let book = Book(title: "本", status: .finished, finishedAt: calendar.date(from: DateComponents(year: 2026, month: 9, day: 10))!)
        let session = MovementSession(type: .walking, performedAt: calendar.date(from: DateComponents(year: 2026, month: 9, day: 15))!)
        let viewModel = makeViewModel(books: [book], movements: [session])

        await viewModel.load()

        #expect(viewModel.summary?.reading.current == 1)
        #expect(viewModel.summary?.movement.current == 1)
    }

    @Test("失敗したら failed")
    func failedWhenRepositoryThrows() async {
        let viewModel = makeViewModel(shouldFail: true)

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test("再読み込みで最新の状態になる")
    func reloadUpdatesState() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        await viewModel.load()

        #expect(viewModel.summary != nil)
    }
}
