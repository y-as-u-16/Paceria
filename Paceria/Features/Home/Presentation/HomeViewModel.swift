import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case loading
        case loaded(HomeSummary)
        case failed
    }

    private(set) var state: State = .loading

    private let getHomeSummary: GetHomeSummaryUseCase
    private let now: @Sendable () -> Date

    init(getHomeSummary: GetHomeSummaryUseCase, now: @escaping @Sendable () -> Date = { .now }) {
        self.getHomeSummary = getHomeSummary
        self.now = now
    }

    var summary: HomeSummary? {
        guard case .loaded(let summary) = state else { return nil }
        return summary
    }

    /// 集計は View の body ではなくここで行う。body に置くと再描画のたびに走る
    /// （docs/04_MVP_AND_ROADMAP.md §11）。
    func load() async {
        do {
            state = .loaded(try await getHomeSummary.execute(on: now()))
        } catch {
            state = .failed
        }
    }
}
