import XCTest

/// App Store 掲載用スクリーンショットを撮る。
///
/// 画像自体は .gitignore で除外しているため、必要になったら再生成する。
///
///     xcodebuild test -project Paceria.xcodeproj -scheme Paceria \
///       -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
///       -parallel-testing-enabled NO \
///       -only-testing:PaceriaUITests/ScreenshotUITests \
///       -resultBundlePath /tmp/shots.xcresult
///
/// 撮れた画像は `xcrun xcresulttool export attachments` で取り出し、
/// fastlane/screenshots/<locale>/ へ置く。
final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))

        seedRecords(app)

        // 掲載順に撮る。1枚目は最も伝えたい画面にする。
        app.tabButton(.home).tap()
        capture(app, name: "01-home")

        app.tabButton(.library).tap()
        capture(app, name: "02-library")

        app.tabButton(.activity).tap()
        capture(app, name: "03-activity")

        app.tabButton(.insights).tap()
        capture(app, name: "04-insights")
    }

    /// 空の画面では魅力が伝わらないため、数件だけ記録を入れてから撮る。
    private func seedRecords(_ app: XCUIApplication) {
        app.tabButton(.activity).tap()
        for type in ["running", "strength"] {
            app.buttons["movement.add"].tap()
            _ = app.buttons["movement.type.\(type)"].waitForExistence(timeout: 5)
            app.buttons["movement.type.\(type)"].tap()
            app.buttons["movement.save"].tap()
            _ = app.collectionViews["movement.list"].waitForExistence(timeout: 5)
        }

        app.tabButton(.library).tap()
        app.buttons["book.add"].tap()
        let title = app.textFields["book.title"]
        _ = title.waitForExistence(timeout: 5)
        title.tap()
        title.typeText("銀河鉄道の夜")
        app.buttons["book.save"].tap()
        _ = app.collectionViews["book.list"].waitForExistence(timeout: 5)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
