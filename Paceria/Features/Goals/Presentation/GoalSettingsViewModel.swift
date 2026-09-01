import Foundation
import Observation

@MainActor
@Observable
final class GoalSettingsViewModel {
    enum State: Equatable {
        case loading
        case loaded(reading: Goal, movement: Goal)
        case failed
    }

    private(set) var state: State = .loading

    private let repository: any GoalRepository

    init(repository: any GoalRepository) {
        self.repository = repository
    }

    var readingGoal: Goal? {
        guard case .loaded(let reading, _) = state else { return nil }
        return reading
    }

    var movementGoal: Goal? {
        guard case .loaded(_, let movement) = state else { return nil }
        return movement
    }

    func load() async {
        state = .loading

        do {
            state = .loaded(
                reading: try await repository.readingGoal(),
                movement: try await repository.movementGoal()
            )
        } catch {
            state = .failed
        }
    }

    func updateReading(target: Int? = nil, period: GoalPeriod? = nil) async {
        guard var goal = readingGoal else { return }
        goal.target = clamp(target ?? goal.target)
        goal.period = period ?? goal.period

        await persist { try await repository.saveReadingGoal(goal) }
    }

    func updateMovement(target: Int? = nil, period: GoalPeriod? = nil) async {
        guard var goal = movementGoal else { return }
        goal.target = clamp(target ?? goal.target)
        goal.period = period ?? goal.period

        await persist { try await repository.saveMovementGoal(goal) }
    }

    /// 0 以下だと達成不能・達成済みの判定が無意味になる。上限は現実的な範囲に留める。
    private func clamp(_ target: Int) -> Int {
        min(max(target, Self.minimumTarget), Self.maximumTarget)
    }

    private func persist(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            await load()
        } catch {
            state = .failed
        }
    }

    static let minimumTarget = 1
    static let maximumTarget = 99
}
