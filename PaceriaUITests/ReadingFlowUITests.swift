import XCTest

final class ReadingFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddsBookThenDeletesIt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()

        app.tabButton(.library).tap()

        app.buttons["book.add"].tap()
        let title = app.textFields["book.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        title.tap()
        title.typeText("銀河鉄道の夜")
        app.buttons["book.save"].tap()

        let list = app.collectionViews["book.list"]
        XCTAssertTrue(list.waitForExistence(timeout: 5), "登録後に本棚が表示されません")
        XCTAssertTrue(app.staticTexts["銀河鉄道の夜"].waitForExistence(timeout: 5), "登録した本が出ません")

        // セクションヘッダーも Cell として数えられるため、
        // 本文のテキストを含む行を指定する。
        let row = list.cells.containing(.staticText, identifier: "銀河鉄道の夜").element
        row.swipeLeft()

        // スワイプで現れる削除ボタンはセルの兄弟として置かれるため、
        // セル配下ではなく app 直下から引く。
        let deleteButton = app.buttons["book.delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "削除ボタンが出ません")
        deleteButton.tap()

        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["銀河鉄道の夜"])
        waitForExpectations(timeout: 5)
    }
}
