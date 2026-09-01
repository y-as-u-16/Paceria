import Foundation

/// 「Exercise」ではなく「Movement」。筋トレに限定せず散歩やスポーツも含める
/// （docs/03_DOMAIN_AND_DATA.md §5）。
enum MovementType: String, Codable, CaseIterable, Sendable {
    case strength
    case running
    case walking
    case sports
    case cycling
    case swimming
    case other
}
