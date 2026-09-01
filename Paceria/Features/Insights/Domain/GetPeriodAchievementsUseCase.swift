import Foundation

struct GetPeriodAchievementsUseCase: Sendable {
    private let bookRepository: any BookRepository
    private let movementRepository: any MovementRepository
    private let calendar: Calendar

    init(
        bookRepository: any BookRepository,
        movementRepository: any MovementRepository,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.bookRepository = bookRepository
        self.movementRepository = movementRepository
        self.calendar = calendar
    }

    /// 古い順に返す。UI は左から右へ時間が進む並びで見せる。
    ///
    /// 進行中の期間は分母に入れない。まだ終わっていない期間を「未達」と数えると、
    /// 週の初日は必ず未達で始まることになり、事実の提示にならない
    /// （docs/01_PRODUCT_REQUIREMENTS.md §12）。
    func execute(goal: Goal, endingAt date: Date, count: Int) async throws -> [PeriodAchievement] {
        guard count > 0 else { return [] }

        let intervals = goal.period.datePeriod
            .recentIntervals(endingAt: date, count: count, in: calendar)
            .filter { $0.end <= date }
            .reversed()

        var achievements: [PeriodAchievement] = []
        for interval in intervals {
            achievements.append(
                PeriodAchievement(
                    period: interval,
                    current: try await recordCount(for: goal.kind, in: interval),
                    target: goal.target
                )
            )
        }
        return achievements
    }

    private func recordCount(for kind: GoalKind, in interval: DateInterval) async throws -> Int {
        switch kind {
        case .finishedBooks: try await bookRepository.finishedCount(in: interval)
        case .movementSessions: try await movementRepository.count(in: interval)
        }
    }
}
