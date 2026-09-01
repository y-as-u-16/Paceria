import Foundation
import SwiftData

@ModelActor
actor SwiftDataGoalRepository: GoalRepository {

    func readingGoal() async throws -> Goal {
        try goal(kind: .finishedBooks)
    }

    func movementGoal() async throws -> Goal {
        try goal(kind: .movementSessions)
    }

    func saveReadingGoal(_ goal: Goal) async throws {
        try save(goal, kind: .finishedBooks)
    }

    func saveMovementGoal(_ goal: Goal) async throws {
        try save(goal, kind: .movementSessions)
    }

    /// 未設定なら既定値を返す。オンボーディング前でも Home を成立させるため、
    /// ここでは永続化しない（読むだけで書き込むと副作用が読みにくい）。
    private func goal(kind: GoalKind) throws -> Goal {
        guard let record = try record(kind: kind) else { return .default(for: kind) }
        return GoalMapper.toDomain(record)
    }

    private func save(_ goal: Goal, kind: GoalKind) throws {
        var goal = goal
        goal.kind = kind

        if let existing = try record(kind: kind) {
            GoalMapper.apply(goal, to: existing, updatedAt: .now)
        } else {
            modelContext.insert(GoalMapper.toRecord(goal, updatedAt: .now))
        }
        try modelContext.save()
    }

    private func record(kind: GoalKind) throws -> GoalRecord? {
        let rawValue = kind.rawValue
        var descriptor = FetchDescriptor<GoalRecord>(predicate: #Predicate { $0.kindRawValue == rawValue })
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }
}
