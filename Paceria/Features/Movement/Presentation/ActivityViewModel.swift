import Foundation
import Observation

@MainActor
@Observable
final class ActivityViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([MovementSession])
        case failed
    }

    private(set) var state: State = .loading

    private let repository: any MovementRepository
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        repository: any MovementRepository,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    /// 履歴は当月ぶんを表示する。全件を無条件に読むと件数が増えたとき破綻する。
    func load() async {
        state = .loading

        do {
            let interval = DatePeriod.month.interval(containing: now(), in: calendar)
            let sessions = try await repository.fetch(in: interval)
            state = sessions.isEmpty ? .empty : .loaded(sessions)
        } catch {
            state = .failed
        }
    }

    func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            state = .failed
        }
    }
}
