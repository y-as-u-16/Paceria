import XCTest

final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testShowsOnboardingOnFirstLaunchThenEntersApp() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboarding"]
        app.launch()

        let start = app.buttons["onboarding.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "初回起動でオンボーディングが出ません")

        start.tap()

        XCTAssertTrue(app.tabButton(.home).waitForExistence(timeout: 5), "本編に入れません")
        XCTAssertFalse(start.exists, "オンボーディングが閉じません")

        // 並列実行では他テストと端末を共有する。完了状態のまま残さないと
        // 後続テストがオンボーディング画面で止まる。
        app.terminate()
    }
}
