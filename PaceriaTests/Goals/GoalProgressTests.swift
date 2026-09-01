import Foundation
import Testing
@testable import Paceria

@Suite("GoalProgress")
struct GoalProgressTests {

    private let period = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 604_800)

    private func progress(_ current: Int, target: Int) -> GoalProgress {
        GoalProgress(
            goal: Goal(kind: .movementSessions, target: target, period: .week),
            current: current,
            period: period
        )
    }

    @Test("目標未達では未達成", arguments: [0, 1])
    func belowTarget(current: Int) {
        let progress = progress(current, target: 2)

        #expect(!progress.isAchieved)
        #expect(progress.remaining == 2 - current)
    }

    @Test("目標到達で達成")
    func atTarget() {
        let progress = progress(2, target: 2)

        #expect(progress.isAchieved)
        #expect(progress.ratio == 1)
        #expect(progress.remaining == 0)
    }

    @Test("超過しても ratio は 1 で頭打ち")
    func aboveTarget() {
        let progress = progress(3, target: 2)

        #expect(progress.isAchieved)
        #expect(progress.ratio == 1)
        #expect(progress.remaining == 0)
    }

    @Test("ratio が進捗を反映する")
    func ratioReflectsProgress() {
        #expect(progress(0, target: 2).ratio == 0)
        #expect(progress(1, target: 2).ratio == 0.5)
    }

    @Test("target が 0 でも 0 除算しない")
    func zeroTarget() {
        #expect(progress(5, target: 0).ratio == 0)
    }

    @Test("target は goal から引く")
    func targetComesFromGoal() {
        #expect(progress(0, target: 7).target == 7)
    }
}

@Suite("Goal defaults")
struct GoalDefaultsTests {

    @Test("読書の既定は 1冊/月")
    func readingDefault() {
        #expect(Goal.defaultReading.target == 1)
        #expect(Goal.defaultReading.period == .month)
        #expect(Goal.defaultReading.kind == .finishedBooks)
    }

    @Test("運動の既定は 2回/週")
    func movementDefault() {
        #expect(Goal.defaultMovement.target == 2)
        #expect(Goal.defaultMovement.period == .week)
        #expect(Goal.defaultMovement.kind == .movementSessions)
    }

    @Test("kind から既定値を引ける")
    func defaultByKind() {
        #expect(Goal.default(for: .finishedBooks) == Goal.defaultReading)
        #expect(Goal.default(for: .movementSessions) == Goal.defaultMovement)
    }

    @Test("GoalPeriod は DatePeriod に対応する")
    func mapsToDatePeriod() {
        #expect(GoalPeriod.week.datePeriod == .week)
        #expect(GoalPeriod.month.datePeriod == .month)
    }
}
