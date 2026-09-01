import Foundation

struct GoalProgress: Equatable, Sendable {
    let goal: Goal
    let current: Int
    let period: DateInterval

    var target: Int { goal.target }

    var ratio: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1)
    }

    var isAchieved: Bool {
        current >= target
    }

    var remaining: Int {
        max(target - current, 0)
    }
}
