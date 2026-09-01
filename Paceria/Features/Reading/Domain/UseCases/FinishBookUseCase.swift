import Foundation

/// 読了処理。status 変更と `finishedAt` 設定を1箇所に閉じる。
///
/// 読了冊数の source of truth は `finishedAt` であって status ではない
/// （docs/03_DOMAIN_AND_DATA.md §9）。両者を別々に更新できる状態にすると、
/// 後から status を戻したときに過去の月次集計が変わってしまう。
struct FinishBookUseCase: Sendable {
    private let repository: any BookRepository
    private let now: @Sendable () -> Date

    init(repository: any BookRepository, now: @escaping @Sendable () -> Date = { .now }) {
        self.repository = repository
        self.now = now
    }

    @discardableResult
    func execute(bookID: UUID) async throws -> Book {
        guard var book = try await repository.fetch(id: bookID) else {
            throw AppError.notFound
        }

        let finishedAt = now()

        // 読み返しで再度読了しても、最初の読了月へ遡って集計が動かないよう
        // finishedAt は毎回更新する。最新の読了が当月の実績になる。
        book.status = .finished
        book.finishedAt = finishedAt
        book.startedAt = book.startedAt ?? finishedAt
        book.updatedAt = finishedAt

        try await repository.save(book)
        return book
    }
}
