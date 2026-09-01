import Foundation

protocol GoalRepository: Sendable {
    func readingGoal() async throws -> Goal
    func movementGoal() async throws -> Goal
    func saveReadingGoal(_ goal: Goal) async throws
    func saveMovementGoal(_ goal: Goal) async throws
}
