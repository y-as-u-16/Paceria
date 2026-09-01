import XCTest

final class RootTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAllTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        // 表示名ではなく identifier で引く。ローカライズを変えてもテストが壊れない。
        for identifier in ["tab.home", "tab.library", "tab.activity", "tab.insights"] {
            let tab = app.tabBars.buttons[identifier]
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(identifier) が見つかりません")

            tab.tap()
            XCTAssertTrue(tab.isSelected, "\(identifier) を選択できません")
        }
    }
}
