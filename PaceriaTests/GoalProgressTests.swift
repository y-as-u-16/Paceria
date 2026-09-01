import Foundation
import Testing
@testable import Paceria

@Suite("GoalProgress")
struct GoalProgressTests {

    private let period = DateInterval(start: .now, duration: 604_800)

    private func progress(current: Int, target: Int) -> GoalProgress {
        GoalProgress(current: current, target: target, period: period)
    }

    @Test("目標未達では isAchieved が false", arguments: [0, 1])
    func belowTargetIsNotAchieved(current: Int) {
        #expect(!progress(current: current, target: 2).isAchieved)
    }

    @Test("目標到達および超過で isAchieved が true", arguments: [2, 3])
    func atOrAboveTargetIsAchieved(current: Int) {
        #expect(progress(current: current, target: 2).isAchieved)
    }

    @Test("ratio は 1 を超えない")
    func ratioIsCapped() {
        #expect(progress(current: 3, target: 2).ratio == 1)
    }

    @Test("ratio が進捗を反映する")
    func ratioReflectsProgress() {
        #expect(progress(current: 1, target: 2).ratio == 0.5)
        #expect(progress(current: 0, target: 2).ratio == 0)
    }

    @Test("target が 0 でも 0 除算しない")
    func zeroTargetDoesNotDivideByZero() {
        #expect(progress(current: 5, target: 0).ratio == 0)
    }

    @Test("remaining は負にならない")
    func remainingIsNeverNegative() {
        #expect(progress(current: 1, target: 2).remaining == 1)
        #expect(progress(current: 3, target: 2).remaining == 0)
    }
}
