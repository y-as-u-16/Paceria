import Foundation
import SwiftData

@Model
final class MovementRecord {
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var performedAt: Date
    var durationMinutes: Int?
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        typeRawValue: String,
        performedAt: Date,
        durationMinutes: Int?,
        note: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.performedAt = performedAt
        self.durationMinutes = durationMinutes
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
