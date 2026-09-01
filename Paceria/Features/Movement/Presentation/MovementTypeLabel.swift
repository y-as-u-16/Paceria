import SwiftUI

extension MovementType {
    /// String Catalog は静的な文字列リテラルしか抽出しない。
    /// `LocalizedStringKey("movement.type.\(rawValue)")` だとキーが未登録扱いになり、
    /// 訳ではなくキー文字列がそのまま表示される。
    var labelKey: LocalizedStringKey {
        switch self {
        case .strength: "movement.type.strength"
        case .running: "movement.type.running"
        case .walking: "movement.type.walking"
        case .sports: "movement.type.sports"
        case .cycling: "movement.type.cycling"
        case .swimming: "movement.type.swimming"
        case .other: "movement.type.other"
        }
    }

    var symbolName: String {
        switch self {
        case .strength: "dumbbell"
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .sports: "sportscourt"
        case .cycling: "bicycle"
        case .swimming: "figure.pool.swim"
        case .other: "figure.mixed.cardio"
        }
    }
}

extension AddMovementError {
    var messageKey: LocalizedStringKey {
        switch self {
        case .invalid(.futureDate): "movement.error.futureDate"
        case .invalid(.durationOutOfRange): "movement.error.durationOutOfRange"
        case .invalid: "movement.error.invalid"
        case .saveFailed: "movement.error.saveFailed"
        }
    }
}
