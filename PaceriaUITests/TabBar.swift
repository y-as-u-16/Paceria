import XCTest

/// SwiftUI の `Tab` は label に付けた accessibilityIdentifier を反映しない。
/// タブは SF Symbol の identifier を持つ Image を子に持つため、そこから引く。
enum TabSymbol: String {
    case home = "house.fill"
    case library = "books.vertical.fill"
    case activity = "figure.walk"
    case insights = "chart.bar.fill"
}

extension XCUIApplication {
    func tabButton(_ symbol: TabSymbol) -> XCUIElement {
        tabBars.buttons.containing(.image, identifier: symbol.rawValue).firstMatch
    }
}
