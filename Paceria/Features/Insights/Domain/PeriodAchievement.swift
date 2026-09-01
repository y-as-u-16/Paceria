import Foundation

struct PeriodAchievement: Equatable, Sendable {
    let period: DateInterval
    let current: Int
    let target: Int

    var isAchieved: Bool {
        current >= target
    }
}

/// 「6 of 8 weeks on pace」という事実の提示に使う。
/// 点数化しない（docs/03_DOMAIN_AND_DATA.md §13）。
struct ConsistencySummary: Equatable, Sendable {
    let achievedPeriods: Int
    let totalPeriods: Int

    /// 記録開始直後は必ず 0/0 を通る。0 除算させない。
    var ratio: Double {
        guard totalPeriods > 0 else { return 0 }
        return Double(achievedPeriods) / Double(totalPeriods)
    }

    var isEmpty: Bool { totalPeriods == 0 }
}

extension ConsistencySummary {
    init(achievements: [PeriodAchievement]) {
        self.init(
            achievedPeriods: achievements.filter(\.isAchieved).count,
            totalPeriods: achievements.count
        )
    }
}
