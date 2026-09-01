import Foundation

enum DatePeriod: String, Codable, Sendable, CaseIterable {
    case week
    case month
}

extension DatePeriod {
    /// 指定日を含む期間の境界を返す。
    ///
    /// 週の開始曜日は `calendar.firstWeekday` に従う。ISO 週固定にすると
    /// 日曜始まりのロケールで「今週」がユーザーの体感と1日ずれる。
    func interval(containing date: Date, in calendar: Calendar = .autoupdatingCurrent) -> DateInterval {
        let component: Calendar.Component = switch self {
        case .week: .weekOfYear
        case .month: .month
        }

        // DST で 0時が存在しない日（南米などで発生）では dateInterval が nil を返す。
        // その場合も期間境界を返さないと集計が破綻するため、日単位へ退避する。
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 0)
        }
        return interval
    }

    func contains(_ date: Date, on referenceDate: Date, in calendar: Calendar = .autoupdatingCurrent) -> Bool {
        interval(containing: referenceDate, in: calendar).containsExcludingEnd(date)
    }

    /// `offset` 期間ぶん過去/未来へずらした期間を返す。Insights の履歴表示で使う。
    func interval(
        containing date: Date,
        offsetBy offset: Int,
        in calendar: Calendar = .autoupdatingCurrent
    ) -> DateInterval {
        let component: Calendar.Component = switch self {
        case .week: .weekOfYear
        case .month: .month
        }

        guard let shifted = calendar.date(byAdding: component, value: offset, to: date) else {
            return interval(containing: date, in: calendar)
        }
        return interval(containing: shifted, in: calendar)
    }

    /// 直近の期間を新しい順に返す。`count` は現在の期間を含む。
    func recentIntervals(
        endingAt date: Date,
        count: Int,
        in calendar: Calendar = .autoupdatingCurrent
    ) -> [DateInterval] {
        guard count > 0 else { return [] }
        return (0..<count).map { interval(containing: date, offsetBy: -$0, in: calendar) }
    }
}

extension DateInterval {
    /// 終端を含まない判定。`DateInterval.contains` は `end` を含むため、
    /// 隣接する期間の境界でカウントが二重になる。
    func containsExcludingEnd(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
