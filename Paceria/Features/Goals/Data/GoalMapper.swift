import Foundation

enum GoalMapper {
    /// 未知の kind / period は既定値へ倒す。目標が読めないと Home 全体が
    /// 表示できなくなるため、壊れた値でも成立させる。
    static func toDomain(_ record: GoalRecord) -> Goal {
        let kind = GoalKind(rawValue: record.kindRawValue) ?? .finishedBooks
        let fallback = Goal.default(for: kind)

        return Goal(
            id: record.id,
            kind: kind,
            target: record.target,
            period: GoalPeriod(rawValue: record.periodRawValue) ?? fallback.period
        )
    }

    static func toRecord(_ goal: Goal, updatedAt: Date) -> GoalRecord {
        GoalRecord(
            id: goal.id,
            kindRawValue: goal.kind.rawValue,
            target: goal.target,
            periodRawValue: goal.period.rawValue,
            updatedAt: updatedAt
        )
    }

    static func apply(_ goal: Goal, to record: GoalRecord, updatedAt: Date) {
        record.target = goal.target
        record.periodRawValue = goal.period.rawValue
        record.updatedAt = updatedAt
    }
}
