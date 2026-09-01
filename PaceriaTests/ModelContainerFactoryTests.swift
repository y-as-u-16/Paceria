import Foundation
import SwiftData
import Testing
@testable import Paceria

@Suite("ModelContainerFactory")
struct ModelContainerFactoryTests {

    @Test("in-memory コンテナを生成できる")
    func createsInMemoryContainer() throws {
        let container = try ModelContainerFactory.makeInMemory()

        #expect(container.configurations.first?.isStoredInMemoryOnly == true)
    }

    @Test("スキーマに3つの Record が含まれる")
    func schemaContainsAllRecords() {
        let names = Set(PaceriaSchemaV1.models.map { String(describing: $0) })

        #expect(names == ["BookRecord", "MovementRecord", "GoalRecord"])
    }

    @Test("保存した Record を取り出せる")
    @MainActor
    func savesAndFetchesRecord() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = container.mainContext
        let id = UUID()

        context.insert(
            MovementRecord(
                id: id,
                typeRawValue: "walk",
                performedAt: .now,
                durationMinutes: 30,
                note: nil,
                createdAt: .now,
                updatedAt: .now
            )
        )
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MovementRecord>())

        #expect(fetched.count == 1)
        #expect(fetched.first?.id == id)
    }

    @Test("コンテナごとに状態が独立している")
    @MainActor
    func containersAreIsolated() throws {
        let first = try ModelContainerFactory.makeInMemory()
        first.mainContext.insert(
            MovementRecord(
                id: UUID(),
                typeRawValue: "run",
                performedAt: .now,
                durationMinutes: nil,
                note: nil,
                createdAt: .now,
                updatedAt: .now
            )
        )
        try first.mainContext.save()

        let second = try ModelContainerFactory.makeInMemory()

        #expect(try second.mainContext.fetch(FetchDescriptor<MovementRecord>()).isEmpty)
    }
}
