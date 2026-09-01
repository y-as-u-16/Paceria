import Foundation

struct GoalProgress: Equatable, Sendable {
    let current: Int
    let target: Int
    let period: DateInterval

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
