import Foundation
import SwiftData

enum PaceriaSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [BookRecord.self, MovementRecord.self, GoalRecord.self]
    }
}

/// V2 追加時にここへ `MigrationStage` を足す（docs/03_DOMAIN_AND_DATA.md §19）。
enum PaceriaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PaceriaSchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}
