import XCTest
@testable import iCodexBar

final class RateWindowTests: XCTestCase {

    // MARK: - Initialization Tests

    func testRateWindowInit() {
        let window = RateWindow(usedPercent: 42.5)
        XCTAssertEqual(window.usedPercent, 42.5)
        XCTAssertNil(window.windowMinutes)
        XCTAssertNil(window.resetsAt)
        XCTAssertNil(window.resetDescription)
    }

    func testRateWindowFullInit() {
        let resetDate = Date().addingTimeInterval(86400)
        let window = RateWindow(
            usedPercent: 75.0,
            windowMinutes: 1440,
            resetsAt: resetDate,
            resetDescription: "in 1 day"
        )

        XCTAssertEqual(window.usedPercent, 75.0)
        XCTAssertEqual(window.windowMinutes, 1440)
        XCTAssertEqual(window.resetsAt, resetDate)
        XCTAssertEqual(window.resetDescription, "in 1 day")
    }

    // MARK: - Remaining Percent Tests

    func testRemainingPercentFromUsed() {
        let window = RateWindow(usedPercent: 30.0)
        XCTAssertEqual(window.remainingPercent, 70.0, accuracy: 0.001)
    }

    func testRemainingPercentClampedHigh() {
        let window = RateWindow(usedPercent: 150.0)
        XCTAssertEqual(window.remainingPercent, 0.0, accuracy: 0.001)
    }

    func testRemainingPercentClampedLow() {
        let window = RateWindow(usedPercent: -10.0)
        XCTAssertEqual(window.remainingPercent, 100.0, accuracy: 0.001)
    }

    func testRemainingPercentExactlyUsed() {
        let window = RateWindow(usedPercent: 100.0)
        XCTAssertEqual(window.remainingPercent, 0.0, accuracy: 0.001)
    }

    func testRemainingPercentZeroUsed() {
        let window = RateWindow(usedPercent: 0.0)
        XCTAssertEqual(window.remainingPercent, 100.0, accuracy: 0.001)
    }

    // MARK: - Codable Tests

    func testRateWindowCodable() throws {
        let window = RateWindow(
            usedPercent: 55.5,
            windowMinutes: 60,
            resetsAt: Date(),
            resetDescription: "in 1 hour"
        )

        let data = try JSONEncoder().encode(window)
        let decoded = try JSONDecoder().decode(RateWindow.self, from: data)
        XCTAssertEqual(decoded.usedPercent, window.usedPercent)
        XCTAssertEqual(decoded.windowMinutes, window.windowMinutes)
        XCTAssertEqual(decoded.resetDescription, window.resetDescription)
    }

    // MARK: - Equatable Tests

    func testRateWindowEquatable() {
        let window1 = RateWindow(usedPercent: 50.0)
        let window2 = RateWindow(usedPercent: 50.0)
        let window3 = RateWindow(usedPercent: 51.0)

        XCTAssertEqual(window1, window2)
        XCTAssertNotEqual(window1, window3)
    }
}
