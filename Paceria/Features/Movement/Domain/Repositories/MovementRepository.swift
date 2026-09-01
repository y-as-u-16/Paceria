import Foundation

protocol MovementRepository: Sendable {
    func fetch(in interval: DateInterval) async throws -> [MovementSession]
    func save(_ session: MovementSession) async throws
    func delete(id: UUID) async throws
    func count(in interval: DateInterval) async throws -> Int
}
