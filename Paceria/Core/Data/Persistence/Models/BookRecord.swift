import Foundation
import SwiftData

@Model
final class BookRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String?
    var statusRawValue: String
    var startedAt: Date?
    var finishedAt: Date?
    var rating: Int?
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        title: String,
        author: String?,
        statusRawValue: String,
        startedAt: Date?,
        finishedAt: Date?,
        rating: Int?,
        note: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.statusRawValue = statusRawValue
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.rating = rating
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
