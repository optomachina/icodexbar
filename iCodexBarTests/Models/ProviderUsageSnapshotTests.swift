import XCTest
@testable import iCodexBar

final class ProviderUsageSnapshotTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSnapshotMinimalInit() {
        let snapshot = ProviderUsageSnapshot(provider: .openAI)

        XCTAssertEqual(snapshot.provider, .openAI)
        XCTAssertNil(snapshot.primary)
        XCTAssertNil(snapshot.secondary)
        XCTAssertNil(snapshot.totalTokens)
        XCTAssertNil(snapshot.totalCostUSD)
        XCTAssertNil(snapshot.balance)
        XCTAssertTrue(snapshot.dailyUsage.isEmpty)
    }

    func testSnapshotFullInit() {
        let primary = RateWindow(usedPercent: 40.0)
        let secondary = RateWindow(usedPercent: 20.0, windowMinutes: 60)
        let daily = [
            DailyUsageEntry(date: Date(), tokens: 1000, cost: 0.05)
        ]

        let snapshot = ProviderUsageSnapshot(
            provider: .anthropic,
            primary: primary,
            secondary: secondary,
            totalTokens: 50000,
            totalCostUSD: 12.34,
            balance: 100.0,
            dailyUsage: daily
        )

        XCTAssertEqual(snapshot.provider, .anthropic)
        XCTAssertNotNil(snapshot.primary)
        XCTAssertNotNil(snapshot.secondary)
        XCTAssertEqual(snapshot.totalTokens, 50000)
        XCTAssertEqual(snapshot.totalCostUSD, 12.34)
        XCTAssertEqual(snapshot.balance, 100.0)
        XCTAssertEqual(snapshot.dailyUsage.count, 1)
    }

    // MARK: - Effective Remaining Percent Tests

    func testEffectiveRemainingPercentFromSecondary() {
        let primary = RateWindow(usedPercent: 50.0)
        let secondary = RateWindow(usedPercent: 25.0)
        let snapshot = ProviderUsageSnapshot(
            provider: .openAI,
            primary: primary,
            secondary: secondary
        )

        XCTAssertEqual(snapshot.effectiveRemainingPercent, 75.0, accuracy: 0.001)
    }

    func testEffectiveRemainingPercentFromPrimaryOnly() {
        let primary = RateWindow(usedPercent: 30.0)
        let snapshot = ProviderUsageSnapshot(
            provider: .openAI,
            primary: primary
        )

        XCTAssertEqual(snapshot.effectiveRemainingPercent, 70.0, accuracy: 0.001)
    }

    func testEffectiveRemainingPercentDefault() {
        let snapshot = ProviderUsageSnapshot(provider: .openAI)
        XCTAssertEqual(snapshot.effectiveRemainingPercent, 100.0, accuracy: 0.001)
    }

    // MARK: - Formatted Output Tests

    func testFormattedCostWithCost() {
        let snapshot = ProviderUsageSnapshot(
            provider: .openAI,
            totalCostUSD: 123.45
        )
        XCTAssertEqual(snapshot.formattedCost, "$123.45")
    }

    func testFormattedCostWithoutCost() {
        let snapshot = ProviderUsageSnapshot(provider: .openAI)
        XCTAssertEqual(snapshot.formattedCost, "—")
    }

    func testFormattedTokensWithTokens() {
        let snapshot = ProviderUsageSnapshot(
            provider: .openAI,
            totalTokens: 1_500_000
        )
        XCTAssertEqual(snapshot.formattedTokens, "1.50M")
    }

    func testFormattedTokensWithoutTokens() {
        let snapshot = ProviderUsageSnapshot(provider: .openAI)
        XCTAssertEqual(snapshot.formattedTokens, "—")
    }

    // MARK: - Codable Tests

    func testSnapshotCodable() throws {
        let snapshot = ProviderUsageSnapshot(
            provider: .openRouter,
            primary: RateWindow(usedPercent: 60.0),
            totalTokens: 100000,
            totalCostUSD: 5.50,
            balance: 25.75
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ProviderUsageSnapshot.self, from: data)

        XCTAssertEqual(decoded.provider, .openRouter)
        XCTAssertEqual(decoded.totalTokens, 100000)
        XCTAssertEqual(decoded.totalCostUSD, 5.50)
        XCTAssertEqual(decoded.balance, 25.75)
    }

    // MARK: - Equatable Tests

    func testSnapshotEquatable() {
        let snapshot1 = ProviderUsageSnapshot(provider: .openAI, totalTokens: 1000)
        let snapshot2 = ProviderUsageSnapshot(provider: .openAI, totalTokens: 1000)
        let snapshot3 = ProviderUsageSnapshot(provider: .openAI, totalTokens: 2000)

        XCTAssertEqual(snapshot1, snapshot2)
        XCTAssertNotEqual(snapshot1, snapshot3)
    }
}
