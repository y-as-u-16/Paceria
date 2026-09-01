import Foundation

/// Goal と基準日から現在の進捗を求める（docs/03_DOMAIN_AND_DATA.md §17）。
///
/// 期間は必ず Calendar 経由で求める。Date の秒差で週を跨ぐと DST のある地域で
/// 1時間ぶんずれ、週の境界がユーザーの体感と食い違う（§8）。
struct CalculateGoalProgressUseCase: Sendable {
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

    func execute(goal: Goal, on date: Date) async throws -> GoalProgress {
        let interval = goal.period.datePeriod.interval(containing: date, in: calendar)

        let current = switch goal.kind {
        case .finishedBooks: try await bookRepository.finishedCount(in: interval)
        case .movementSessions: try await movementRepository.count(in: interval)
        }

        return GoalProgress(goal: goal, current: current, period: interval)
    }
}
