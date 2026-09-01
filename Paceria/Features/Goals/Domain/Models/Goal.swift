import Foundation

enum GoalKind: String, Codable, CaseIterable, Sendable {
    case finishedBooks
    case movementSessions
}

enum GoalPeriod: String, Codable, CaseIterable, Sendable {
    case week
    case month
}

struct Goal: Identifiable, Equatable, Sendable {
    let id: UUID
    var kind: GoalKind
    var target: Int
    var period: GoalPeriod

    init(id: UUID = UUID(), kind: GoalKind, target: Int, period: GoalPeriod) {
        self.id = id
        self.kind = kind
        self.target = target
        self.period = period
    }
}

extension Goal {
    /// オンボーディング未実施でも Home が成立するよう既定値を持つ
    /// （docs/03_DOMAIN_AND_DATA.md §6）。
    static let defaultReading = Goal(kind: .finishedBooks, target: 1, period: .month)
    static let defaultMovement = Goal(kind: .movementSessions, target: 2, period: .week)

    static func `default`(for kind: GoalKind) -> Goal {
        switch kind {
        case .finishedBooks: .defaultReading
        case .movementSessions: .defaultMovement
        }
    }
}

extension GoalPeriod {
    var datePeriod: DatePeriod {
        switch self {
        case .week: .week
        case .month: .month
        }
    }
}
