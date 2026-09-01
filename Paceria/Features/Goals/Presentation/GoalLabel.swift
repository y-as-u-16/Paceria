import SwiftUI

extension GoalPeriod {
    var labelKey: LocalizedStringKey {
        switch self {
        case .week: "goals.period.week"
        case .month: "goals.period.month"
        }
    }
}

extension Goal {
    /// 冊と回で単位が違う。複数形の扱いは String Catalog に任せる。
    func unitKey(count: Int) -> LocalizedStringKey {
        switch kind {
        case .finishedBooks: "goals.unit.books \(count)"
        case .movementSessions: "goals.unit.sessions \(count)"
        }
    }
}
