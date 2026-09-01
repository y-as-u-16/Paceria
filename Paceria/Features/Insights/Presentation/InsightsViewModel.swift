import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
    struct Section: Equatable {
        let goal: Goal
        let achievements: [PeriodAchievement]
        let consistency: ConsistencySummary
        let currentProgress: GoalProgress
    }

    enum State: Equatable {
        case loading
        case loaded(reading: Section, movement: Section)
        case failed
    }

    static let movementPeriodCount = 8
    static let readingPeriodCount = 6

    private(set) var state: State = .loading

    private let goalRepository: any GoalRepository
    private let getAchievements: GetPeriodAchievementsUseCase
    private let calculateProgress: CalculateGoalProgressUseCase
    private let now: @Sendable () -> Date

    init(
        goalRepository: any GoalRepository,
        getAchievements: GetPeriodAchievementsUseCase,
        calculateProgress: CalculateGoalProgressUseCase,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.goalRepository = goalRepository
        self.getAchievements = getAchievements
        self.calculateProgress = calculateProgress
        self.now = now
    }

    func load() async {
        do {
            let date = now()
            state = .loaded(
                reading: try await section(
                    goal: try await goalRepository.readingGoal(),
                    count: Self.readingPeriodCount,
                    on: date
                ),
                movement: try await section(
                    goal: try await goalRepository.movementGoal(),
                    count: Self.movementPeriodCount,
                    on: date
                )
            )
        } catch {
            state = .failed
        }
    }

    private func section(goal: Goal, count: Int, on date: Date) async throws -> Section {
        let achievements = try await getAchievements.execute(goal: goal, endingAt: date, count: count)

        return Section(
            goal: goal,
            achievements: achievements,
            consistency: ConsistencySummary(achievements: achievements),
            currentProgress: try await calculateProgress.execute(goal: goal, on: date)
        )
    }
}
