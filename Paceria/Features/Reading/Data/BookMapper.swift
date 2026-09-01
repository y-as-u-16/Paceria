import Foundation

enum BookMapper {
    /// 未知の status は wantToRead へ倒す。旧バージョンや将来の値で
    /// 蔵書が読み出せなくなるのを防ぐ。
    static func toDomain(_ record: BookRecord) -> Book {
        Book(
            id: record.id,
            title: record.title,
            author: record.author,
            isbn: record.isbn,
            coverURL: record.coverURL,
            status: ReadingStatus(rawValue: record.statusRawValue) ?? .wantToRead,
            startedAt: record.startedAt,
            finishedAt: record.finishedAt,
            rating: record.rating,
            note: record.note,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    static func toRecord(_ book: Book) -> BookRecord {
        BookRecord(
            id: book.id,
            title: book.title,
            author: book.author,
            isbn: book.isbn,
            coverURL: book.coverURL,
            statusRawValue: book.status.rawValue,
            startedAt: book.startedAt,
            finishedAt: book.finishedAt,
            rating: book.rating,
            note: book.note,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt
        )
    }

    static func apply(_ book: Book, to record: BookRecord) {
        record.title = book.title
        record.author = book.author
        record.isbn = book.isbn
        record.coverURL = book.coverURL
        record.statusRawValue = book.status.rawValue
        record.startedAt = book.startedAt
        record.finishedAt = book.finishedAt
        record.rating = book.rating
        record.note = book.note
        record.updatedAt = book.updatedAt
    }
}
