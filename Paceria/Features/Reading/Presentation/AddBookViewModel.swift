import Foundation
import Observation

@MainActor
@Observable
final class AddBookViewModel {
    /// 手入力で30秒以内に登録できるよう、必須はタイトルのみ
    /// （docs/04_MVP_AND_ROADMAP.md §12）。
    var title: String = ""
    var author: String = ""
    var status: ReadingStatus = .reading

    private(set) var isSaving = false
    private(set) var error: BookFormError?

    private let repository: any BookRepository
    private let now: @Sendable () -> Date

    init(repository: any BookRepository, now: @escaping @Sendable () -> Date = { .now }) {
        self.repository = repository
        self.now = now
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() async -> Bool {
        guard !isSaving else { return false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            error = .invalid(.emptyTitle)
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let timestamp = now()
        let book = Book(
            title: trimmedTitle,
            author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
            status: status,
            startedAt: status == .reading ? timestamp : nil,
            finishedAt: status == .finished ? timestamp : nil,
            createdAt: timestamp,
            updatedAt: timestamp
        )

        do {
            try await repository.save(book)
            error = nil
            return true
        } catch {
            self.error = .saveFailed
            return false
        }
    }
}

enum BookFormError: Equatable {
    case invalid(ValidationError)
    case saveFailed
}
