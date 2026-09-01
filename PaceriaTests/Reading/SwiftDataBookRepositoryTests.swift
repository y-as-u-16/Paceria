import Foundation
import SwiftData
import Testing
@testable import Paceria

@Suite("SwiftDataBookRepository")
struct SwiftDataBookRepositoryTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private var september: DateInterval {
        DatePeriod.month.interval(containing: date(2026, 9, 15), in: calendar)
    }

    private func makeRepository() throws -> SwiftDataBookRepository {
        SwiftDataBookRepository(modelContainer: try ModelContainerFactory.makeInMemory())
    }

    @Test("保存した本を取得できる")
    func savesAndFetches() async throws {
        let repository = try makeRepository()
        let book = Book(title: "銀河鉄道の夜", author: "宮沢賢治", status: .reading)

        try await repository.save(book)

        #expect(try await repository.fetch(id: book.id) == book)
    }

    @Test("すべての項目が往復しても失われない")
    func roundTripsAllFields() async throws {
        let repository = try makeRepository()
        let book = Book(
            title: "本",
            author: "著者",
            isbn: "9784000000000",
            coverURL: URL(string: "https://example.com/cover.jpg"),
            status: .finished,
            startedAt: date(2026, 9, 1),
            finishedAt: date(2026, 9, 10),
            rating: 5,
            note: "よかった"
        )

        try await repository.save(book)

        #expect(try await repository.fetch(id: book.id) == book)
    }

    @Test("同じ ID で保存すると更新され、重複しない")
    func savingSameIDUpdates() async throws {
        let repository = try makeRepository()
        var book = Book(title: "旧題", status: .wantToRead)
        try await repository.save(book)

        book.title = "新題"
        book.status = .reading
        try await repository.save(book)

        let all = try await repository.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.title == "新題")
    }

    @Test("status で絞り込める")
    func filtersByStatus() async throws {
        let repository = try makeRepository()
        let reading = Book(title: "読書中", status: .reading)
        try await repository.save(reading)
        try await repository.save(Book(title: "読みたい", status: .wantToRead))

        let fetched = try await repository.fetch(status: .reading)

        #expect(fetched.map(\.id) == [reading.id])
    }

    @Test("削除できる")
    func deletesBook() async throws {
        let repository = try makeRepository()
        let book = Book(title: "本")
        try await repository.save(book)

        try await repository.delete(id: book.id)

        #expect(try await repository.fetch(id: book.id) == nil)
    }

    @Test("存在しない ID の削除は notFound")
    func deletingUnknownIDThrows() async throws {
        let repository = try makeRepository()

        await #expect(throws: AppError.notFound) {
            try await repository.delete(id: UUID())
        }
    }

    @Test("当月に読了した本が数えられる")
    func countsBooksFinishedInMonth() async throws {
        let repository = try makeRepository()
        try await repository.save(Book(title: "本", status: .finished, finishedAt: date(2026, 9, 10)))

        #expect(try await repository.finishedCount(in: september) == 1)
    }

    @Test("前月に読了した本は当月に数えない")
    func excludesPreviousMonth() async throws {
        let repository = try makeRepository()
        try await repository.save(Book(title: "本", status: .finished, finishedAt: date(2026, 8, 31)))

        #expect(try await repository.finishedCount(in: september) == 0)
    }

    @Test("翌月に読了した本は当月に数えない")
    func excludesNextMonth() async throws {
        let repository = try makeRepository()
        try await repository.save(Book(title: "本", status: .finished, finishedAt: date(2026, 10, 1)))

        #expect(try await repository.finishedCount(in: september) == 0)
    }

    @Test("月初ちょうどの読了は当月に入る")
    func includesMonthStart() async throws {
        let repository = try makeRepository()
        try await repository.save(Book(title: "本", status: .finished, finishedAt: september.start))

        #expect(try await repository.finishedCount(in: september) == 1)
    }

    @Test("月末の境界は翌月に属し、二重カウントされない")
    func excludesMonthEnd() async throws {
        let repository = try makeRepository()
        try await repository.save(Book(title: "本", status: .finished, finishedAt: september.end))

        let october = DatePeriod.month.interval(containing: date(2026, 10, 15), in: calendar)

        #expect(try await repository.finishedCount(in: september) == 0)
        #expect(try await repository.finishedCount(in: october) == 1)
    }

    @Test("finishedAt が無ければ status が finished でも数えない")
    func requiresFinishedAtNotStatus() async throws {
        let repository = try makeRepository()

        // 集計の source of truth は finishedAt（docs/03 §9）。
        try await repository.save(Book(title: "本", status: .finished, finishedAt: nil))

        #expect(try await repository.finishedCount(in: september) == 0)
    }

    @Test("status が finished でなくても finishedAt があれば数える")
    func countsByFinishedAtEvenIfStatusChanged() async throws {
        let repository = try makeRepository()

        // 読了後に status を戻しても、過去の実績は動かない。
        try await repository.save(Book(title: "本", status: .reading, finishedAt: date(2026, 9, 10)))

        #expect(try await repository.finishedCount(in: september) == 1)
    }

    @Test("未知の status は wantToRead として読み出される")
    func unknownStatusFallsBack() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = SwiftDataBookRepository(modelContainer: container)
        let context = ModelContext(container)
        context.insert(
            BookRecord(
                id: UUID(), title: "本", author: nil, isbn: nil, coverURL: nil,
                statusRawValue: "abandoned", startedAt: nil, finishedAt: nil,
                rating: nil, note: nil, createdAt: .now, updatedAt: .now
            )
        )
        try context.save()

        #expect(try await repository.fetchAll().first?.status == .wantToRead)
    }
}
