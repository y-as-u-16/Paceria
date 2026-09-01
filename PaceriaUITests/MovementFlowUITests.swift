import XCTest

final class MovementFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLogsMovementThenDeletesIt() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["tab.activity"].tap()

        let list = app.collectionViews["movement.list"]
        let initialCount = list.exists ? list.cells.count : 0

        app.buttons["movement.add"].tap()
        XCTAssertTrue(app.buttons["movement.type.running"].waitForExistence(timeout: 5))

        app.buttons["movement.type.running"].tap()
        app.buttons["movement.save"].tap()

        XCTAssertTrue(list.waitForExistence(timeout: 5), "記録後に履歴が表示されません")
        XCTAssertEqual(list.cells.count, initialCount + 1, "記録が履歴に追加されていません")

        list.cells.element(boundBy: 0).swipeLeft()

        // スワイプで現れる削除ボタンはセルの子ではなく app 直下に出る。
        // 表示名はロケール依存のため identifier で引く。
        let deleteButton = app.buttons["movement.delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "削除ボタンが出ません")
        deleteButton.tap()

        let listEmptied = NSPredicate(format: "count == %d", initialCount)
        expectation(for: listEmptied, evaluatedWith: list.cells)
        waitForExpectations(timeout: 5)
    }
}
