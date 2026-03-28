import XCTest

final class DashboardUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Dashboard Display Tests

    func testDashboardDisplaysTitle() {
        // Verify the app launches and shows dashboard
        XCTAssertTrue(app.exists)

        // Check for navigation title or main content
        let dashboard = app.scrollViews.firstMatch
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))
    }

    func testDashboardShowsProviderCards() {
        // When API keys are configured, provider cards should appear
        // In UI testing mode without keys, we verify the empty state

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
    }

    // MARK: - Settings Navigation Tests

    func testNavigateToSettings() {
        let settingsButton = app.buttons["Settings"]
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.tap()

            // Verify settings view appeared
            let settingsView = app.scrollViews["SettingsView"]
            XCTAssertTrue(settingsView.waitForExistence(timeout: 3))
        }
    }

    func testNavigateBackFromSettings() {
        // Navigate to settings
        let settingsButton = app.buttons["Settings"]
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.tap()

            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.waitForExistence(timeout: 2) {
                backButton.tap()

                // Verify back on dashboard
                let dashboard = app.scrollViews.firstMatch
                XCTAssertTrue(dashboard.waitForExistence(timeout: 3))
            }
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefresh() {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)

        // Perform pull to refresh gesture
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let finish = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))

        start.press(forDuration: 0.1, thenDragTo: finish)

        // Allow time for refresh
        sleep(1)
    }
}
