import XCTest
@testable import iCodexBar

final class AlertThresholdTests: XCTestCase {

    // MARK: - Initialization Tests

    func testAlertThresholdDefaultInit() {
        let threshold = AlertThreshold(provider: .openAI)

        XCTAssertEqual(threshold.provider, .openAI)
        XCTAssertEqual(threshold.thresholdPercent, 80)
        XCTAssertTrue(threshold.isEnabled)
        XCTAssertNotNil(threshold.id)
    }

    func testAlertThresholdCustomInit() {
        let threshold = AlertThreshold(
            provider: .anthropic,
            thresholdPercent: 50,
            isEnabled: false
        )

        XCTAssertEqual(threshold.provider, .anthropic)
        XCTAssertEqual(threshold.thresholdPercent, 50)
        XCTAssertFalse(threshold.isEnabled)
    }

    // MARK: - AlertThresholdStore Tests

    func testStoreDefaultInit() {
        let store = AlertThresholdStore()
        XCTAssertEqual(store.thresholds.count, Provider.allCases.count)
    }

    func testStoreThresholdForProvider() {
        let store = AlertThresholdStore()
        let threshold = store.threshold(for: .openAI)

        XCTAssertNotNil(threshold)
        XCTAssertEqual(threshold?.provider, .openAI)
    }

    func testStoreUpdateExisting() {
        var store = AlertThresholdStore()
        var threshold = store.threshold(for: .openAI)!
        threshold.thresholdPercent = 90

        store.update(threshold)

        XCTAssertEqual(store.threshold(for: .openAI)?.thresholdPercent, 90)
    }

    func testStoreSetEnabled() {
        var store = AlertThresholdStore()
        store.setEnabled(false, for: .anthropic)

        XCTAssertFalse(store.threshold(for: .anthropic)!.isEnabled)
    }

    func testStoreSetThresholdPercent() {
        var store = AlertThresholdStore()
        store.setThresholdPercent(75, for: .openRouter)

        XCTAssertEqual(store.threshold(for: .openRouter)?.thresholdPercent, 75)
    }

    func testStoreThresholdPercentClampedHigh() {
        var store = AlertThresholdStore()
        store.setThresholdPercent(150, for: .openAI)

        XCTAssertEqual(store.threshold(for: .openAI)?.thresholdPercent, 100)
    }

    func testStoreThresholdPercentClampedLow() {
        var store = AlertThresholdStore()
        store.setThresholdPercent(-10, for: .openAI)

        XCTAssertEqual(store.threshold(for: .openAI)?.thresholdPercent, 1)
    }

    // MARK: - Codable Tests

    func testAlertThresholdCodable() throws {
        let threshold = AlertThreshold(provider: .openRouter, thresholdPercent: 65)
        let data = try JSONEncoder().encode(threshold)
        let decoded = try JSONDecoder().decode(AlertThreshold.self, from: data)

        XCTAssertEqual(decoded.provider, .openRouter)
        XCTAssertEqual(decoded.thresholdPercent, 65)
    }

    func testStoreCodable() throws {
        var store = AlertThresholdStore()
        store.setThresholdPercent(45, for: .anthropic)
        store.setEnabled(false, for: .openAI)

        let data = try JSONEncoder().encode(store)
        let decoded = try JSONDecoder().decode(AlertThresholdStore.self, from: data)

        XCTAssertEqual(decoded.threshold(for: .anthropic)?.thresholdPercent, 45)
        XCTAssertFalse(decoded.threshold(for: .openAI)!.isEnabled)
    }

    // MARK: - Equatable Tests

    func testAlertThresholdEquatable() {
        let id = UUID()
        var t1 = AlertThreshold(provider: .openAI)
        var t2 = AlertThreshold(provider: .openAI)

        // Different IDs should not be equal
        XCTAssertNotEqual(t1, t2)

        // Same ID should be equal
        t1 = AlertThreshold(provider: .openAI, thresholdPercent: 80)
        t2 = AlertThreshold(provider: .openAI, thresholdPercent: 80)
        // Still different IDs
        XCTAssertNotEqual(t1, t2)
    }
}
