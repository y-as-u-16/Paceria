import Foundation

enum MovementMapper {
    /// Record の type が未知の文字列でも失敗させず other へ倒す。
    /// 旧バージョンで保存した値やスキーマ変更で、履歴が丸ごと消えるのを防ぐ。
    static func toDomain(_ record: MovementRecord) -> MovementSession {
        MovementSession(
            id: record.id,
            type: MovementType(rawValue: record.typeRawValue) ?? .other,
            performedAt: record.performedAt,
            durationMinutes: record.durationMinutes,
            note: record.note,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    static func toRecord(_ session: MovementSession) -> MovementRecord {
        MovementRecord(
            id: session.id,
            typeRawValue: session.type.rawValue,
            performedAt: session.performedAt,
            durationMinutes: session.durationMinutes,
            note: session.note,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt
        )
    }

    static func apply(_ session: MovementSession, to record: MovementRecord) {
        record.typeRawValue = session.type.rawValue
        record.performedAt = session.performedAt
        record.durationMinutes = session.durationMinutes
        record.note = session.note
        record.updatedAt = session.updatedAt
    }
}
