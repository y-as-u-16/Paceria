import Foundation
import SwiftData

enum ModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: PaceriaSchemaV1.self)
        let configuration = if inMemory {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            ModelConfiguration(schema: schema, url: try storeURL())
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: PaceriaMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// テスト専用。ディスクを汚さず、テスト間で状態が漏れない。
    static func makeInMemory() throws -> ModelContainer {
        try make(inMemory: true)
    }

    /// Application Support は初回起動時に存在しないことがあり、その場合
    /// SwiftData のストア生成が失敗する。先に作ってから URL を渡す。
    private static func storeURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return directory.appending(path: "Paceria.store")
    }
}
