import Foundation

struct HomeSummary: Equatable, Sendable {
    let reading: GoalProgress
    let movement: GoalProgress
    let recentWins: [RecentWin]
}

/// feed にしない。直近の手応えを思い出させるだけの存在
/// （docs/03_DOMAIN_AND_DATA.md §15）。
enum RecentWin: Equatable, Sendable {
    case bookStarted(title: String)
    case bookFinished(title: String)
    case movementLogged(type: MovementType)
    case readingGoalAchieved
    case movementGoalAchieved
}
