import Foundation
import Testing
@testable import Paceria

@Suite("ActivityViewModel")
@MainActor
struct ActivityViewModelTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()

    /// 2026-09-15 12:00 UTC。当月は 09-01 〜 10-01。
    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 12))!
    }

    private func makeViewModel(_ repository: MovementRepositorySpy) -> ActivityViewModel {
        let now = referenceDate
        return ActivityViewModel(repository: repository, calendar: calendar, now: { now })
    }

    private func session(day: Int, month: Int = 9) -> MovementSession {
        MovementSession(
            type: .walking,
            performedAt: calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 9))!
        )
    }

    @Test("初期状態は loading")
    func initialStateIsLoading() {
        #expect(makeViewModel(MovementRepositorySpy()).state == .loading)
    }

    @Test("記録が無ければ empty")
    func emptyWhenNoSessions() async {
        let viewModel = makeViewModel(MovementRepositorySpy())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("記録があれば loaded")
    func loadedWhenSessionsExist() async {
        let expected = session(day: 10)
        let viewModel = makeViewModel(MovementRepositorySpy(sessions: [expected]))

        await viewModel.load()

        #expect(viewModel.state == .loaded([expected]))
    }

    @Test("当月ぶんだけ読み込む")
    func loadsOnlyCurrentMonth() async {
        let inMonth = session(day: 10)
        let viewModel = makeViewModel(
            MovementRepositorySpy(sessions: [inMonth, session(day: 20, month: 8), session(day: 2, month: 10)])
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded([inMonth]))
    }

    @Test("失敗したら failed")
    func failedWhenRepositoryThrows() async {
        let viewModel = makeViewModel(MovementRepositorySpy(shouldFail: true))

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test("削除すると一覧から消える")
    func deleteRemovesSession() async {
        let target = session(day: 10)
        let repository = MovementRepositorySpy(sessions: [target])
        let viewModel = makeViewModel(repository)
        await viewModel.load()

        await viewModel.delete(id: target.id)

        #expect(viewModel.state == .empty)
        #expect(await repository.deletedIDs == [target.id])
    }

    @Test("削除に失敗したら failed")
    func deleteFailureSetsFailedState() async {
        let target = session(day: 10)
        let repository = MovementRepositorySpy(sessions: [target])
        let viewModel = makeViewModel(repository)
        await viewModel.load()

        await repository.setShouldFail(true)
        await viewModel.delete(id: target.id)

        #expect(viewModel.state == .failed)
    }

    @Test("失敗後に再読み込みすると回復する")
    func recoversAfterFailure() async {
        let repository = MovementRepositorySpy(sessions: [session(day: 10)], shouldFail: true)
        let viewModel = makeViewModel(repository)
        await viewModel.load()

        await repository.setShouldFail(false)
        await viewModel.load()

        #expect(viewModel.state != .failed)
    }
}
