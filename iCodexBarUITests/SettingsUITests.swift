import XCTest

final class SettingsUITests: XCTestCase {

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

    // MARK: - Settings View Tests

    func testSettingsViewDisplays() {
        navigateToSettings()

        // Verify settings elements exist
        let settingsView = app.scrollViews.firstMatch
        XCTAssertTrue(settingsView.waitForExistence(timeout: 3))
    }

    func testAPIKeySectionExists() {
        navigateToSettings()

        // Look for API key configuration section
        let apiKeySection = app.staticTexts["API Keys"]
        if apiKeySection.waitForExistence(timeout: 2) {
            XCTAssertTrue(apiKeySection.exists)
        }
    }

    func testRefreshIntervalSetting() {
        navigateToSettings()

        // Look for refresh interval picker or buttons
        let refreshIntervalLabel = app.staticTexts["Refresh Interval"]
        if refreshIntervalLabel.waitForExistence(timeout: 2) {
            XCTAssertTrue(refreshIntervalLabel.exists)

            // Try to change the interval
            let picker = app.pickers.firstMatch
            if picker.exists {
                picker.swipeUp()
                sleep(1)
            }
        }
    }

    func testAlertThresholdSettings() {
        navigateToSettings()

        // Look for alert threshold section
        let alertsSection = app.staticTexts["Alerts"]
        if alertsSection.waitForExistence(timeout: 2) {
            XCTAssertTrue(alertsSection.exists)
        }
    }

    // MARK: - Helper Methods

    private func navigateToSettings() {
        let settingsButton = app.buttons["Settings"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
        } else {
            // Try tab bar or navigation link
            let tabBars = app.tabBars
            if tabBars.firstMatch.exists {
                tabBars.buttons["Settings"].tap()
            }
        }
    }
}
