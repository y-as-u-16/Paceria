import Foundation
import SwiftData
import Testing
@testable import Paceria

@Suite("SwiftDataMovementRepository")
struct SwiftDataMovementRepositoryTests {

    private func makeRepository() throws -> SwiftDataMovementRepository {
        SwiftDataMovementRepository(modelContainer: try ModelContainerFactory.makeInMemory())
    }

    private func session(
        id: UUID = UUID(),
        type: MovementType = .walking,
        at performedAt: Date,
        durationMinutes: Int? = nil,
        note: String? = nil
    ) -> MovementSession {
        MovementSession(
            id: id,
            type: type,
            performedAt: performedAt,
            durationMinutes: durationMinutes,
            note: note
        )
    }

    private var interval: DateInterval {
        DateInterval(start: Date(timeIntervalSince1970: 1_000_000), duration: 604_800)
    }

    @Test("保存した記録を取得できる")
    func savesAndFetches() async throws {
        let repository = try makeRepository()
        let saved = session(type: .running, at: interval.start.addingTimeInterval(3600), durationMinutes: 30, note: "朝ラン")

        try await repository.save(saved)
        let fetched = try await repository.fetch(in: interval)

        #expect(fetched.count == 1)
        #expect(fetched.first == saved)
    }

    @Test("すべての任意項目が往復しても失われない")
    func roundTripsOptionalFields() async throws {
        let repository = try makeRepository()
        let saved = session(at: interval.start.addingTimeInterval(60), durationMinutes: nil, note: nil)

        try await repository.save(saved)

        #expect(try await repository.fetch(in: interval).first == saved)
    }

    @Test("同じ ID で保存すると更新され、重複しない")
    func savingSameIDUpdatesInsteadOfDuplicating() async throws {
        let repository = try makeRepository()
        let id = UUID()
        try await repository.save(session(id: id, type: .walking, at: interval.start.addingTimeInterval(60)))

        try await repository.save(session(id: id, type: .swimming, at: interval.start.addingTimeInterval(60), durationMinutes: 45))
        let fetched = try await repository.fetch(in: interval)

        #expect(fetched.count == 1)
        #expect(fetched.first?.type == .swimming)
        #expect(fetched.first?.durationMinutes == 45)
    }

    @Test("削除すると取得できなくなる")
    func deletesSession() async throws {
        let repository = try makeRepository()
        let id = UUID()
        try await repository.save(session(id: id, at: interval.start.addingTimeInterval(60)))

        try await repository.delete(id: id)

        #expect(try await repository.fetch(in: interval).isEmpty)
    }

    @Test("存在しない ID の削除は notFound を投げる")
    func deletingUnknownIDThrows() async throws {
        let repository = try makeRepository()

        await #expect(throws: AppError.notFound) {
            try await repository.delete(id: UUID())
        }
    }

    @Test("期間の開始ちょうどは含まれる")
    func includesIntervalStart() async throws {
        let repository = try makeRepository()
        try await repository.save(session(at: interval.start))

        #expect(try await repository.count(in: interval) == 1)
    }

    @Test("期間の終端は含まれない。隣接期間で二重カウントされない")
    func excludesIntervalEnd() async throws {
        let repository = try makeRepository()
        try await repository.save(session(at: interval.end))

        let next = DateInterval(start: interval.end, duration: 604_800)

        #expect(try await repository.count(in: interval) == 0)
        #expect(try await repository.count(in: next) == 1)
    }

    @Test("期間外の記録は取得されない")
    func excludesOutsideInterval() async throws {
        let repository = try makeRepository()
        try await repository.save(session(at: interval.start.addingTimeInterval(-1)))
        try await repository.save(session(at: interval.end.addingTimeInterval(1)))

        #expect(try await repository.fetch(in: interval).isEmpty)
    }

    @Test("新しい順に並ぶ")
    func sortsByPerformedAtDescending() async throws {
        let repository = try makeRepository()
        let older = session(at: interval.start.addingTimeInterval(60))
        let newer = session(at: interval.start.addingTimeInterval(7200))

        try await repository.save(older)
        try await repository.save(newer)
        let fetched = try await repository.fetch(in: interval)

        #expect(fetched.map(\.id) == [newer.id, older.id])
    }

    @Test("同日に複数記録してもそれぞれ数える")
    func countsMultipleSessionsOnSameDay() async throws {
        let repository = try makeRepository()
        let day = interval.start.addingTimeInterval(3600)

        try await repository.save(session(at: day))
        try await repository.save(session(at: day.addingTimeInterval(1800)))

        // MVP では1日1件へ丸めない（docs/03_DOMAIN_AND_DATA.md §10）。
        #expect(try await repository.count(in: interval) == 2)
    }

    @Test("記録が無ければ count は 0")
    func countsZeroWhenEmpty() async throws {
        #expect(try await makeRepository().count(in: interval) == 0)
    }

    @Test("未知の種目は other として読み出される")
    func unknownTypeFallsBackToOther() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = SwiftDataMovementRepository(modelContainer: container)

        // 将来のバージョンが保存した種目を、旧バージョンが読む状況を再現する。
        let context = ModelContext(container)
        context.insert(
            MovementRecord(
                id: UUID(),
                typeRawValue: "yoga",
                performedAt: interval.start.addingTimeInterval(60),
                durationMinutes: nil,
                note: nil,
                createdAt: .now,
                updatedAt: .now
            )
        )
        try context.save()

        #expect(try await repository.fetch(in: interval).first?.type == .other)
    }
}
