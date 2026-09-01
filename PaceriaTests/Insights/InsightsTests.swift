import Foundation
import Testing
@testable import Paceria

@Suite("ConsistencySummary")
struct ConsistencySummaryTests {

    private func achievements(_ flags: [Bool]) -> [PeriodAchievement] {
        flags.enumerated().map { index, achieved in
            PeriodAchievement(
                period: DateInterval(start: Date(timeIntervalSince1970: Double(index) * 604_800), duration: 604_800),
                current: achieved ? 2 : 1,
                target: 2
            )
        }
    }

    @Test("達成数を数える")
    func countsAchieved() {
        let summary = ConsistencySummary(achievements: achievements([true, true, false, true]))

        #expect(summary.achievedPeriods == 3)
        #expect(summary.totalPeriods == 4)
    }

    @Test("空配列では 0 / 0。記録開始直後に必ず通る")
    func handlesEmpty() {
        let summary = ConsistencySummary(achievements: [])

        #expect(summary.achievedPeriods == 0)
        #expect(summary.totalPeriods == 0)
        #expect(summary.isEmpty)
        #expect(summary.ratio == 0)
    }

    @Test("全達成・全未達も破綻しない")
    func handlesExtremes() {
        #expect(ConsistencySummary(achievements: achievements([true, true])).ratio == 1)
        #expect(ConsistencySummary(achievements: achievements([false, false])).ratio == 0)
    }
}

@Suite("PeriodAchievement")
struct PeriodAchievementTests {

    private func achievement(current: Int, target: Int) -> PeriodAchievement {
        PeriodAchievement(
            period: DateInterval(start: Date(timeIntervalSince1970: 0), duration: 604_800),
            current: current,
            target: target
        )
    }

    @Test("目標到達で達成", arguments: [2, 3])
    func achievedAtOrAbove(current: Int) {
        #expect(achievement(current: current, target: 2).isAchieved)
    }

    @Test("目標未満では未達成", arguments: [0, 1])
    func notAchievedBelow(current: Int) {
        #expect(!achievement(current: current, target: 2).isAchieved)
    }
}

@Suite("GetPeriodAchievementsUseCase")
struct GetPeriodAchievementsUseCaseTests {

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
    ) -> GetPeriodAchievementsUseCase {
        GetPeriodAchievementsUseCase(
            bookRepository: BookRepositorySpy(books: books),
            movementRepository: MovementRepositorySpy(sessions: movements),
            calendar: calendar
        )
    }

    private func movement(_ year: Int, _ month: Int, _ day: Int) -> MovementSession {
        MovementSession(type: .walking, performedAt: date(year, month, day))
    }

    @Test("記録が無ければ達成ゼロで並ぶ")
    func returnsUnachievedWhenNoRecords() async throws {
        // 2026-09-15 火曜。進行中の週は除かれるため 4 件要求で 3 件返る。
        let achievements = try await makeUseCase()
            .execute(goal: .defaultMovement, endingAt: date(2026, 9, 15), count: 4)

        #expect(achievements.allSatisfy { !$0.isAchieved })
    }

    @Test("進行中の期間は分母に入れない")
    func excludesCurrentPeriod() async throws {
        let achievements = try await makeUseCase()
            .execute(goal: .defaultMovement, endingAt: date(2026, 9, 15), count: 4)

        // 今週（09-14〜09-21）はまだ終わっていない。
        #expect(achievements.count == 3)
        #expect(achievements.allSatisfy { $0.period.end <= date(2026, 9, 15) })
    }

    @Test("古い順に並ぶ")
    func sortsOldestFirst() async throws {
        let achievements = try await makeUseCase()
            .execute(goal: .defaultMovement, endingAt: date(2026, 9, 15), count: 4)

        for (older, newer) in zip(achievements, achievements.dropFirst()) {
            #expect(older.period.start < newer.period.start)
        }
    }

    @Test("達成した週だけ達成になる")
    func marksAchievedWeeks() async throws {
        // 先週 09-07〜09-14 に2回、その前の週は1回だけ。
        let useCase = makeUseCase(movements: [
            movement(2026, 9, 8), movement(2026, 9, 9),
            movement(2026, 9, 1),
        ])

        let achievements = try await useCase
            .execute(goal: .defaultMovement, endingAt: date(2026, 9, 15), count: 3)

        #expect(achievements.last?.isAchieved == true)
        #expect(achievements.dropLast().last?.isAchieved == false)
    }

    @Test("月次の読書も集計できる")
    func aggregatesMonthlyReading() async throws {
        let useCase = makeUseCase(books: [
            Book(title: "本", status: .finished, finishedAt: date(2026, 8, 10)),
        ])

        let achievements = try await useCase
            .execute(goal: .defaultReading, endingAt: date(2026, 9, 15), count: 3)

        #expect(achievements.last?.isAchieved == true)
    }

    @Test("count が 0 以下なら空を返す", arguments: [0, -1])
    func rejectsNonPositiveCount(count: Int) async throws {
        let achievements = try await makeUseCase()
            .execute(goal: .defaultMovement, endingAt: date(2026, 9, 15), count: count)

        #expect(achievements.isEmpty)
    }

    @Test("期間の終端ちょうどに基準日があれば、その期間は完了扱い")
    func includesPeriodEndingExactlyNow() async throws {
        // 09-14 00:00 は前週の終端であり今週の開始。前週は完了している。
        let boundary = DatePeriod.week.interval(containing: date(2026, 9, 15), in: calendar).start

        let achievements = try await makeUseCase()
            .execute(goal: .defaultMovement, endingAt: boundary, count: 2)

        #expect(achievements.contains { $0.period.end == boundary })
    }

    @Test("目標値の変更が達成判定に反映される")
    func respectsTarget() async throws {
        let useCase = makeUseCase(movements: [movement(2026, 9, 8)])
        let goal = Goal(kind: .movementSessions, target: 1, period: .week)

        let achievements = try await useCase.execute(goal: goal, endingAt: date(2026, 9, 15), count: 2)

        #expect(achievements.last?.isAchieved == true)
    }
}

@Suite("InsightsViewModel")
@MainActor
struct InsightsViewModelTests {

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
        movements: [MovementSession] = [],
        shouldFail: Bool = false
    ) -> InsightsViewModel {
        let bookRepository = BookRepositorySpy(shouldFail: shouldFail)
        let movementRepository = MovementRepositorySpy(sessions: movements, shouldFail: shouldFail)
        let now = referenceDate

        return InsightsViewModel(
            goalRepository: GoalRepositoryStub(),
            getAchievements: GetPeriodAchievementsUseCase(
                bookRepository: bookRepository,
                movementRepository: movementRepository,
                calendar: calendar
            ),
            calculateProgress: CalculateGoalProgressUseCase(
                bookRepository: bookRepository,
                movementRepository: movementRepository,
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

        guard case .loaded(let reading, let movement) = viewModel.state else {
            Issue.record("loaded になりません")
            return
        }
        #expect(movement.consistency.achievedPeriods == 0)
        #expect(reading.consistency.achievedPeriods == 0)
    }

    @Test("運動は直近8週ぶんを対象にする")
    func usesEightWeeksForMovement() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        guard case .loaded(_, let movement) = viewModel.state else { return }
        // 進行中の週は除かれるため 7 件。
        #expect(movement.achievements.count == InsightsViewModel.movementPeriodCount - 1)
    }

    @Test("失敗したら failed")
    func failedWhenRepositoryThrows() async {
        let viewModel = makeViewModel(shouldFail: true)

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }
}
