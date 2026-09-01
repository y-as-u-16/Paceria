import SwiftUI

/// System の semantic style で足りるものは独自定義しない（Issue #14 §20）。
/// 数値の可読性だけはアプリ固有の要求があるため、ここだけ定義する。
enum Typography {
    /// 進捗の「2 / 3」を読み違えないよう等幅の数字を使う。
    static let metric: Font = .system(.title, design: .rounded).weight(.medium)
}
