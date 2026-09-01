import XCTest

final class RootTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAllTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "タブバーが出ません")

        for symbol in [TabSymbol.home, .library, .activity, .insights] {
            let tab = app.tabButton(symbol)
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(symbol.rawValue) が見つかりません")

            tab.tap()
            XCTAssertTrue(tab.isSelected, "\(symbol.rawValue) を選択できません")
        }
    }
}
