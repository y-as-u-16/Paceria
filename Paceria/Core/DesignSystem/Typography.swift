import SwiftUI

enum Typography {
    /// Dynamic Type に追従させるため、固定サイズではなく semantic style を返す。
    static let screenTitle: Font = .largeTitle.weight(.semibold)
    static let sectionTitle: Font = .title3.weight(.semibold)
    static let cardTitle: Font = .headline
    static let body: Font = .body
    static let caption: Font = .caption
    static let metric: Font = .system(.title, design: .rounded).weight(.medium)
}
