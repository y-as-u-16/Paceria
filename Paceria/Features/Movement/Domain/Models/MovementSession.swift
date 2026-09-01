import Foundation

struct MovementSession: Identifiable, Equatable, Sendable {
    let id: UUID

    var type: MovementType
    var performedAt: Date
    var durationMinutes: Int?
    var note: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        type: MovementType,
        performedAt: Date,
        durationMinutes: Int? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.performedAt = performedAt
        self.durationMinutes = durationMinutes
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
