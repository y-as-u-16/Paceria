import Foundation

struct GetHomeSummaryUseCase: Sendable {
    static let maximumRecentWins = 3

    private let goalRepository: any GoalRepository
    private let bookRepository: any BookRepository
    private let movementRepository: any MovementRepository
    private let calculateProgress: CalculateGoalProgressUseCase
    private let calendar: Calendar

    init(
        goalRepository: any GoalRepository,
        bookRepository: any BookRepository,
        movementRepository: any MovementRepository,
        calculateProgress: CalculateGoalProgressUseCase,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.goalRepository = goalRepository
        self.bookRepository = bookRepository
        self.movementRepository = movementRepository
        self.calculateProgress = calculateProgress
        self.calendar = calendar
    }

    func execute(on date: Date) async throws -> HomeSummary {
        let reading = try await calculateProgress.execute(goal: try await goalRepository.readingGoal(), on: date)
        let movement = try await calculateProgress.execute(goal: try await goalRepository.movementGoal(), on: date)

        return HomeSummary(
            reading: reading,
            movement: movement,
            recentWins: try await recentWins(reading: reading, movement: movement, on: date)
        )
    }

    private func recentWins(
        reading: GoalProgress,
        movement: GoalProgress,
        on date: Date
    ) async throws -> [RecentWin] {
        var wins: [RecentWin] = []

        // 達成は最も伝えたい事実なので先頭に置く。
        if reading.isAchieved { wins.append(.readingGoalAchieved) }
        if movement.isAchieved { wins.append(.movementGoalAchieved) }

        let books = try await bookRepository.fetchAll()
        let sessions = try await movementRepository.fetch(in: movement.period)

        wins.append(contentsOf: bookWins(books, in: reading.period))
        wins.append(contentsOf: sessions.prefix(Self.maximumRecentWins).map { .movementLogged(type: $0.type) })

        return Array(wins.prefix(Self.maximumRecentWins))
    }

    private func bookWins(_ books: [Book], in interval: DateInterval) -> [RecentWin] {
        let finished = books
            .filter { $0.finishedAt.map(interval.containsExcludingEnd) ?? false }
            .sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) }
            .map { RecentWin.bookFinished(title: $0.title) }

        let started = books
            .filter { $0.status == .reading && ($0.startedAt.map(interval.containsExcludingEnd) ?? false) }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
            .map { RecentWin.bookStarted(title: $0.title) }

        return finished + started
    }
}
