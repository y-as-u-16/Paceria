import Foundation

struct Book: Identifiable, Equatable, Sendable {
    let id: UUID

    var title: String
    var author: String?
    var isbn: String?
    var coverURL: URL?

    var status: ReadingStatus

    var startedAt: Date?
    var finishedAt: Date?

    var rating: Int?
    var note: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        isbn: String? = nil,
        coverURL: URL? = nil,
        status: ReadingStatus = .wantToRead,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        rating: Int? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn = isbn
        self.coverURL = coverURL
        self.status = status
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.rating = rating
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
