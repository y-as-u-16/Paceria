import Foundation
import Testing
@testable import Paceria

@Suite("CalculateGoalProgressUseCase")
struct CalculateGoalProgressUseCaseTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func makeUseCase(
        books: [Book] = [],
        movements: [MovementSession] = []
    ) -> CalculateGoalProgressUseCase {
        CalculateGoalProgressUseCase(
            bookRepository: BookRepositorySpy(books: books),
            movementRepository: MovementRepositorySpy(sessions: movements),
            calendar: calendar
        )
    }

    private func movement(_ year: Int, _ month: Int, _ day: Int) -> MovementSession {
        MovementSession(type: .walking, performedAt: date(year, month, day))
    }

    private func finishedBook(_ year: Int, _ month: Int, _ day: Int) -> Book {
        Book(title: "本", status: .finished, finishedAt: date(year, month, day))
    }

    @Test("今週の運動回数を数える")
    func countsMovementsInCurrentWeek() async throws {
        // 2026-09-15 は火曜。月曜始まりの週は 09-14 〜 09-21。
        let useCase = makeUseCase(movements: [movement(2026, 9, 14), movement(2026, 9, 16)])

        let progress = try await useCase.execute(goal: .defaultMovement, on: date(2026, 9, 15))

        #expect(progress.current == 2)
        #expect(progress.isAchieved)
    }

    @Test("前週・翌週の運動は数えない")
    func excludesAdjacentWeeks() async throws {
        let useCase = makeUseCase(movements: [movement(2026, 9, 13), movement(2026, 9, 21)])

        let progress = try await useCase.execute(goal: .defaultMovement, on: date(2026, 9, 15))

        #expect(progress.current == 0)
    }

    @Test("今月の読了冊数を数える")
    func countsBooksFinishedInCurrentMonth() async throws {
        let useCase = makeUseCase(books: [finishedBook(2026, 9, 1), finishedBook(2026, 9, 30)])

        let progress = try await useCase.execute(goal: .defaultReading, on: date(2026, 9, 15))

        #expect(progress.current == 2)
    }

    @Test("前月・翌月の読了は数えない")
    func excludesAdjacentMonths() async throws {
        let useCase = makeUseCase(books: [finishedBook(2026, 8, 31), finishedBook(2026, 10, 1)])

        let progress = try await useCase.execute(goal: .defaultReading, on: date(2026, 9, 15))

        #expect(progress.current == 0)
    }

    @Test("返る期間が goal の期間と一致する")
    func returnsMatchingInterval() async throws {
        let useCase = makeUseCase()

        let weekly = try await useCase.execute(goal: .defaultMovement, on: date(2026, 9, 15))
        let monthly = try await useCase.execute(goal: .defaultReading, on: date(2026, 9, 15))

        #expect(weekly.period == DatePeriod.week.interval(containing: date(2026, 9, 15), in: calendar))
        #expect(monthly.period == DatePeriod.month.interval(containing: date(2026, 9, 15), in: calendar))
    }

    @Test("記録が無ければ 0 で未達成")
    func zeroWhenNoRecords() async throws {
        let progress = try await makeUseCase().execute(goal: .defaultMovement, on: date(2026, 9, 15))

        #expect(progress.current == 0)
        #expect(!progress.isAchieved)
        #expect(progress.remaining == 2)
    }

    @Test("年を跨ぐ週でも正しく数える")
    func countsAcrossYearBoundary() async throws {
        // 2026-12-31 は木曜。週は 12-28 〜 翌年 01-04。
        let useCase = makeUseCase(movements: [movement(2026, 12, 29), movement(2027, 1, 2)])

        let progress = try await useCase.execute(goal: .defaultMovement, on: date(2026, 12, 31))

        #expect(progress.current == 2)
    }

    @Test("閏年の2月29日も当月に入る")
    func countsLeapDay() async throws {
        let useCase = makeUseCase(books: [finishedBook(2028, 2, 29)])

        let progress = try await useCase.execute(goal: .defaultReading, on: date(2028, 2, 10))

        #expect(progress.current == 1)
    }

    @Test("同じ日に複数回記録してもそれぞれ数える")
    func countsMultipleSessionsSameDay() async throws {
        // MVP では1日1回へ丸めない（docs/03 §10）。
        let useCase = makeUseCase(movements: [movement(2026, 9, 15), movement(2026, 9, 15)])

        let progress = try await useCase.execute(goal: .defaultMovement, on: date(2026, 9, 15))

        #expect(progress.current == 2)
    }

    @Test("目標値を変えると達成判定も変わる")
    func respectsCustomTarget() async throws {
        let useCase = makeUseCase(movements: [movement(2026, 9, 15)])
        let goal = Goal(kind: .movementSessions, target: 1, period: .week)

        let progress = try await useCase.execute(goal: goal, on: date(2026, 9, 15))

        #expect(progress.isAchieved)
    }

    @Test("読書目標を週にすると集計期間も週になる")
    func respectsCustomPeriod() async throws {
        let useCase = makeUseCase(books: [finishedBook(2026, 9, 1)])
        let goal = Goal(kind: .finishedBooks, target: 1, period: .week)

        let progress = try await useCase.execute(goal: goal, on: date(2026, 9, 15))

        // 09-01 は 09-14 週の外。
        #expect(progress.current == 0)
    }
}
