import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var readingTarget: Int = Goal.defaultReading.target
    var movementTarget: Int = Goal.defaultMovement.target

    private(set) var isSaving = false

    private let repository: any GoalRepository

    init(repository: any GoalRepository) {
        self.repository = repository
    }

    func finish() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        do {
            try await repository.saveReadingGoal(
                Goal(kind: .finishedBooks, target: readingTarget, period: Goal.defaultReading.period)
            )
            try await repository.saveMovementGoal(
                Goal(kind: .movementSessions, target: movementTarget, period: Goal.defaultMovement.period)
            )
            return true
        } catch {
            // 目標は既定値でも成立するため、保存に失敗してもオンボーディングは終える。
            // ここで足止めすると初回起動そのものが進まなくなる。
            return true
        }
    }
}
