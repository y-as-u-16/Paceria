import Foundation
import SwiftData

@Model
final class GoalRecord {
    @Attribute(.unique) var id: UUID
    /// GoalKind ごとに1件だけ存在する。重複すると目標判定の対象が曖昧になる。
    @Attribute(.unique) var kindRawValue: String
    var target: Int
    var periodRawValue: String
    var updatedAt: Date

    init(
        id: UUID,
        kindRawValue: String,
        target: Int,
        periodRawValue: String,
        updatedAt: Date
    ) {
        self.id = id
        self.kindRawValue = kindRawValue
        self.target = target
        self.periodRawValue = periodRawValue
        self.updatedAt = updatedAt
    }
}
