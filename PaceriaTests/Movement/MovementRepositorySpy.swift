import Foundation
@testable import Paceria

/// ViewModel テスト用。SwiftData を介さず状態遷移だけを検証する。
actor MovementRepositorySpy: MovementRepository {
    enum Failure: Error { case forced }

    private var sessions: [MovementSession]
    private var shouldFail: Bool

    private(set) var savedSessions: [MovementSession] = []
    private(set) var deletedIDs: [UUID] = []

    init(sessions: [MovementSession] = [], shouldFail: Bool = false) {
        self.sessions = sessions
        self.shouldFail = shouldFail
    }

    func fetch(in interval: DateInterval) async throws -> [MovementSession] {
        if shouldFail { throw Failure.forced }
        return sessions.filter { interval.containsExcludingEnd($0.performedAt) }
    }

    func save(_ session: MovementSession) async throws {
        if shouldFail { throw Failure.forced }
        savedSessions.append(session)
        sessions.append(session)
    }

    func delete(id: UUID) async throws {
        if shouldFail { throw Failure.forced }
        deletedIDs.append(id)
        sessions.removeAll { $0.id == id }
    }

    func count(in interval: DateInterval) async throws -> Int {
        if shouldFail { throw Failure.forced }
        return sessions.filter { interval.containsExcludingEnd($0.performedAt) }.count
    }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }
}
