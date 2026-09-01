import SwiftUI

/// 文言はこのアプリの思想が最も出る場所。「サボっている」「失敗」の類は使わない
/// （docs/04_MVP_AND_ROADMAP.md §13）。
enum HomeCopy {
    static func headline(for progress: GoalProgress) -> LocalizedStringKey {
        guard !progress.isAchieved else {
            return progress.goal.kind == .finishedBooks
                ? "home.reading.achieved"
                : "home.movement.achieved"
        }

        return switch (progress.goal.kind, progress.goal.period) {
        case (.finishedBooks, .week): "home.reading.remaining.week \(progress.remaining)"
        case (.finishedBooks, .month): "home.reading.remaining.month \(progress.remaining)"
        case (.movementSessions, .week): "home.movement.remaining.week \(progress.remaining)"
        case (.movementSessions, .month): "home.movement.remaining.month \(progress.remaining)"
        }
    }
}

extension RecentWin {
    var messageKey: LocalizedStringKey {
        switch self {
        case .bookStarted(let title): "home.win.bookStarted \(title)"
        case .bookFinished(let title): "home.win.bookFinished \(title)"
        case .movementLogged: "home.win.movementLogged"
        case .readingGoalAchieved: "home.win.readingGoalAchieved"
        case .movementGoalAchieved: "home.win.movementGoalAchieved"
        }
    }

    var symbolName: String {
        switch self {
        case .bookStarted: "book"
        case .bookFinished: "checkmark.circle"
        case .movementLogged(let type): type.symbolName
        case .readingGoalAchieved, .movementGoalAchieved: "sparkles"
        }
    }
}
