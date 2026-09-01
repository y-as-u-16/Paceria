import Foundation
import Testing
@testable import Paceria

@Suite("GetHomeSummaryUseCase")
struct GetHomeSummaryUseCaseTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// 2026-09-15 は火曜。週は 09-14〜09-21、月は 09-01〜10-01。
    private var referenceDate: Date { date(2026, 9, 15) }

    private func makeUseCase(
        books: [Book] = [],
        movements: [MovementSession] = [],
        goals: GoalRepositoryStub = GoalRepositoryStub()
    ) -> GetHomeSummaryUseCase {
        let bookRepository = BookRepositorySpy(books: books)
        let movementRepository = MovementRepositorySpy(sessions: movements)

        return GetHomeSummaryUseCase(
            goalRepository: goals,
            bookRepository: bookRepository,
            movementRepository: movementRepository,
            calculateProgress: CalculateGoalProgressUseCase(
                bookRepository: bookRepository,
                movementRepository: movementRepository,
                calendar: calendar
            ),
            calendar: calendar
        )
    }

    private func movement(_ day: Int, type: MovementType = .walking) -> MovementSession {
        MovementSession(type: type, performedAt: date(2026, 9, day))
    }

    private func finishedBook(_ title: String, day: Int) -> Book {
        Book(title: title, status: .finished, finishedAt: date(2026, 9, day))
    }

    @Test("読書と運動の進捗が両方返る")
    func returnsBothProgresses() async throws {
        let summary = try await makeUseCase(
            books: [finishedBook("本", day: 10)],
            movements: [movement(15)]
        ).execute(on: referenceDate)

        #expect(summary.reading.current == 1)
        #expect(summary.movement.current == 1)
    }

    @Test("記録が無くても成立する")
    func worksWithNoRecords() async throws {
        let summary = try await makeUseCase().execute(on: referenceDate)

        #expect(summary.reading.current == 0)
        #expect(summary.movement.current == 0)
        #expect(summary.recentWins.isEmpty)
    }

    @Test("目標達成が Recent Wins の先頭に来る")
    func achievementComesFirst() async throws {
        let summary = try await makeUseCase(
            books: [finishedBook("本", day: 10)],
            movements: [movement(14), movement(15)]
        ).execute(on: referenceDate)

        #expect(summary.recentWins.first == .readingGoalAchieved)
        #expect(summary.recentWins.contains(.movementGoalAchieved))
    }

    @Test("Recent Wins は最大3件")
    func limitsRecentWins() async throws {
        let summary = try await makeUseCase(
            books: [finishedBook("A", day: 8), finishedBook("B", day: 9), finishedBook("C", day: 10)],
            movements: [movement(14), movement(15), movement(16)]
        ).execute(on: referenceDate)

        #expect(summary.recentWins.count == GetHomeSummaryUseCase.maximumRecentWins)
    }

    @Test("読了した本が Recent Wins に出る")
    func includesFinishedBook() async throws {
        let summary = try await makeUseCase(books: [finishedBook("銀河鉄道の夜", day: 10)])
            .execute(on: referenceDate)

        #expect(summary.recentWins.contains(.bookFinished(title: "銀河鉄道の夜")))
    }

    @Test("読み始めた本が Recent Wins に出る")
    func includesStartedBook() async throws {
        let book = Book(title: "読書中の本", status: .reading, startedAt: date(2026, 9, 10))

        let summary = try await makeUseCase(books: [book]).execute(on: referenceDate)

        #expect(summary.recentWins.contains(.bookStarted(title: "読書中の本")))
    }

    @Test("運動が Recent Wins に出る")
    func includesMovement() async throws {
        let summary = try await makeUseCase(movements: [movement(15, type: .swimming)])
            .execute(on: referenceDate)

        #expect(summary.recentWins.contains(.movementLogged(type: .swimming)))
    }

    @Test("期間外の記録は Recent Wins に出ない")
    func excludesOutOfPeriodRecords() async throws {
        let summary = try await makeUseCase(
            books: [finishedBook("前月の本", day: 1).with(finishedAt: date(2026, 8, 20))],
            movements: [movement(1)]
        ).execute(on: referenceDate)

        #expect(summary.recentWins.isEmpty)
    }

    @Test("目標を変えると達成判定も変わる")
    func respectsCustomGoals() async throws {
        let goals = GoalRepositoryStub(
            reading: Goal(kind: .finishedBooks, target: 2, period: .month),
            movement: Goal(kind: .movementSessions, target: 1, period: .week)
        )

        let summary = try await makeUseCase(
            books: [finishedBook("本", day: 10)],
            movements: [movement(15)],
            goals: goals
        ).execute(on: referenceDate)

        #expect(!summary.reading.isAchieved)
        #expect(summary.movement.isAchieved)
    }
}

private extension Book {
    func with(finishedAt: Date) -> Book {
        var copy = self
        copy.finishedAt = finishedAt
        return copy
    }
}

actor GoalRepositoryStub: GoalRepository {
    private var reading: Goal
    private var movement: Goal

    init(reading: Goal = .defaultReading, movement: Goal = .defaultMovement) {
        self.reading = reading
        self.movement = movement
    }

    func readingGoal() async throws -> Goal { reading }
    func movementGoal() async throws -> Goal { movement }
    func saveReadingGoal(_ goal: Goal) async throws { reading = goal }
    func saveMovementGoal(_ goal: Goal) async throws { movement = goal }
}
