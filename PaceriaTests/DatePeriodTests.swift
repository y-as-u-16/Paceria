import Foundation
import Testing
@testable import Paceria

/// 実行環境のロケール・タイムゾーンでテスト結果が変わらないよう固定する。
private func makeCalendar(
    timeZone: String = "UTC",
    firstWeekday: Int = 2
) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: timeZone)!
    calendar.firstWeekday = firstWeekday
    return calendar
}

private func date(
    _ year: Int, _ month: Int, _ day: Int,
    _ hour: Int = 12, _ minute: Int = 0,
    in calendar: Calendar
) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

@Suite("DatePeriod week boundaries")
struct DatePeriodWeekTests {

    @Test("週の開始は firstWeekday に従う")
    func weekStartsOnFirstWeekday() {
        let calendar = makeCalendar()
        // 2026-09-02 は水曜日。月曜始まりなら週の開始は 08-31。
        let interval = DatePeriod.week.interval(containing: date(2026, 9, 2, in: calendar), in: calendar)

        #expect(interval.start == date(2026, 8, 31, 0, 0, in: calendar))
        #expect(interval.end == date(2026, 9, 7, 0, 0, in: calendar))
    }

    @Test("日曜始まりロケールでは週の開始が1日ずれる")
    func weekRespectsSundayFirstWeekday() {
        let calendar = makeCalendar(firstWeekday: 1)
        let interval = DatePeriod.week.interval(containing: date(2026, 9, 2, in: calendar), in: calendar)

        #expect(interval.start == date(2026, 8, 30, 0, 0, in: calendar))
    }

    @Test("週の開始ちょうどの時刻は当該週に含まれる")
    func weekStartIsInclusive() {
        let calendar = makeCalendar()
        let reference = date(2026, 9, 2, in: calendar)
        let start = date(2026, 8, 31, 0, 0, in: calendar)

        #expect(DatePeriod.week.contains(start, on: reference, in: calendar))
    }

    @Test("週の終端は翌週に属し、二重カウントされない")
    func weekEndIsExclusive() {
        let calendar = makeCalendar()
        let reference = date(2026, 9, 2, in: calendar)
        let interval = DatePeriod.week.interval(containing: reference, in: calendar)

        #expect(!DatePeriod.week.contains(interval.end, on: reference, in: calendar))
        #expect(DatePeriod.week.contains(interval.end, on: interval.end, in: calendar))
    }

    @Test("年を跨ぐ週が分断されない")
    func weekSpansYearBoundary() {
        let calendar = makeCalendar()
        // 2026-12-31 は木曜日。月曜始まりの週は 12-28 〜 翌年 01-04。
        let interval = DatePeriod.week.interval(containing: date(2026, 12, 31, in: calendar), in: calendar)

        #expect(interval.start == date(2026, 12, 28, 0, 0, in: calendar))
        #expect(interval.end == date(2027, 1, 4, 0, 0, in: calendar))
        #expect(DatePeriod.week.contains(date(2027, 1, 1, in: calendar), on: date(2026, 12, 31, in: calendar), in: calendar))
    }

    @Test("前週・翌週は現在の週に含まれない")
    func adjacentWeeksExcluded() {
        let calendar = makeCalendar()
        let reference = date(2026, 9, 2, in: calendar)

        #expect(!DatePeriod.week.contains(date(2026, 8, 30, in: calendar), on: reference, in: calendar))
        #expect(!DatePeriod.week.contains(date(2026, 9, 7, in: calendar), on: reference, in: calendar))
    }
}

@Suite("DatePeriod month boundaries")
struct DatePeriodMonthTests {

    @Test("月の境界が月初と翌月初になる")
    func monthInterval() {
        let calendar = makeCalendar()
        let interval = DatePeriod.month.interval(containing: date(2026, 9, 15, in: calendar), in: calendar)

        #expect(interval.start == date(2026, 9, 1, 0, 0, in: calendar))
        #expect(interval.end == date(2026, 10, 1, 0, 0, in: calendar))
    }

    @Test("閏年の2月は29日を含む")
    func leapYearFebruary() {
        let calendar = makeCalendar()
        let interval = DatePeriod.month.interval(containing: date(2028, 2, 10, in: calendar), in: calendar)

        #expect(interval.end == date(2028, 3, 1, 0, 0, in: calendar))
        #expect(DatePeriod.month.contains(date(2028, 2, 29, in: calendar), on: date(2028, 2, 10, in: calendar), in: calendar))
    }

    @Test("非閏年の2月は28日で終わる")
    func nonLeapYearFebruary() {
        let calendar = makeCalendar()
        let interval = DatePeriod.month.interval(containing: date(2026, 2, 10, in: calendar), in: calendar)

        #expect(interval.end == date(2026, 3, 1, 0, 0, in: calendar))
    }

    @Test("12月の翌月境界が翌年1月になる")
    func decemberRollsIntoNextYear() {
        let calendar = makeCalendar()
        let interval = DatePeriod.month.interval(containing: date(2026, 12, 15, in: calendar), in: calendar)

        #expect(interval.end == date(2027, 1, 1, 0, 0, in: calendar))
    }

    @Test("前月・翌月は現在の月に含まれない")
    func adjacentMonthsExcluded() {
        let calendar = makeCalendar()
        let reference = date(2026, 9, 15, in: calendar)

        #expect(!DatePeriod.month.contains(date(2026, 8, 31, 23, 59, in: calendar), on: reference, in: calendar))
        #expect(!DatePeriod.month.contains(date(2026, 10, 1, 0, 0, in: calendar), on: reference, in: calendar))
    }
}

@Suite("DatePeriod timezone and DST")
struct DatePeriodTimeZoneTests {

    @Test("タイムゾーンが変わると月境界の絶対時刻も変わる")
    func monthBoundaryShiftsWithTimeZone() {
        let tokyo = makeCalendar(timeZone: "Asia/Tokyo")
        let utc = makeCalendar()

        let tokyoStart = DatePeriod.month.interval(containing: date(2026, 9, 15, in: tokyo), in: tokyo).start
        let utcStart = DatePeriod.month.interval(containing: date(2026, 9, 15, in: utc), in: utc).start

        // 東京の 9/1 0:00 は UTC の 8/31 15:00。9時間ぶん先行する。
        #expect(tokyoStart < utcStart)
        #expect(utcStart.timeIntervalSince(tokyoStart) == 9 * 3600)
    }

    @Test("DST 開始を含む週は168時間より1時間短い")
    func weekContainingDaylightSavingStartIsShorter() {
        let calendar = makeCalendar(timeZone: "America/New_York")
        // 2026-03-08(日) に DST 開始。月曜始まりなので 03-02 週がこれを含む。
        let interval = DatePeriod.week.interval(containing: date(2026, 3, 4, in: calendar), in: calendar)

        // 秒差で週を計算してはならない根拠。
        #expect(interval.duration == 7 * 24 * 3600 - 3600)
    }

    @Test("DST 終了を含む週は168時間より1時間長い")
    func weekContainingDaylightSavingEndIsLonger() {
        let calendar = makeCalendar(timeZone: "America/New_York")
        // 2026-11-01(日) に DST 終了。月曜始まりなので 10-26 週がこれを含む。
        let interval = DatePeriod.week.interval(containing: date(2026, 10, 28, in: calendar), in: calendar)

        #expect(interval.duration == 7 * 24 * 3600 + 3600)
    }

    @Test("DST を跨いでも日付の所属週は変わらない")
    func daylightSavingDoesNotShiftMembership() {
        let calendar = makeCalendar(timeZone: "America/New_York")
        let reference = date(2026, 3, 4, in: calendar)

        // DST 移行日の前後がどちらも同じ週に属する。
        #expect(DatePeriod.week.contains(date(2026, 3, 7, in: calendar), on: reference, in: calendar))
        #expect(DatePeriod.week.contains(date(2026, 3, 8, in: calendar), on: reference, in: calendar))
    }
}

@Suite("DatePeriod offsets")
struct DatePeriodOffsetTests {

    @Test("負のオフセットで前の期間を返す")
    func negativeOffsetReturnsPreviousPeriod() {
        let calendar = makeCalendar()
        let interval = DatePeriod.month.interval(containing: date(2026, 9, 15, in: calendar), offsetBy: -1, in: calendar)

        #expect(interval.start == date(2026, 8, 1, 0, 0, in: calendar))
    }

    @Test("年を跨いで遡れる")
    func offsetAcrossYearBoundary() {
        let calendar = makeCalendar()
        let interval = DatePeriod.month.interval(containing: date(2026, 1, 15, in: calendar), offsetBy: -1, in: calendar)

        #expect(interval.start == date(2025, 12, 1, 0, 0, in: calendar))
    }

    @Test("オフセット0は現在の期間と一致する")
    func zeroOffsetMatchesCurrent() {
        let calendar = makeCalendar()
        let reference = date(2026, 9, 15, in: calendar)

        #expect(
            DatePeriod.week.interval(containing: reference, offsetBy: 0, in: calendar)
                == DatePeriod.week.interval(containing: reference, in: calendar)
        )
    }

    @Test("直近の期間が新しい順に隙間なく並ぶ")
    func recentIntervalsAreContiguousAndDescending() {
        let calendar = makeCalendar()
        let intervals = DatePeriod.week.recentIntervals(endingAt: date(2026, 9, 15, in: calendar), count: 4, in: calendar)

        #expect(intervals.count == 4)
        for (newer, older) in zip(intervals, intervals.dropFirst()) {
            #expect(older.end == newer.start)
        }
    }

    @Test("count が 0 以下なら空を返す")
    func recentIntervalsRejectsNonPositiveCount() {
        let calendar = makeCalendar()
        let reference = date(2026, 9, 15, in: calendar)

        #expect(DatePeriod.week.recentIntervals(endingAt: reference, count: 0, in: calendar).isEmpty)
        #expect(DatePeriod.week.recentIntervals(endingAt: reference, count: -1, in: calendar).isEmpty)
    }
}
