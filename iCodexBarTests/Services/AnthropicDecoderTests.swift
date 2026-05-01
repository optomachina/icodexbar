@testable import iCodexBarCore
import XCTest

/// Fixture-backed decoder coverage for Anthropic responses.
final class AnthropicDecoderTests: XCTestCase {
    /// Verifies the basic OAuth usage fixture decodes the correct window utilizations and reset dates.
    func testOAuthUsageBasicDecodesUsage() throws {
        let decoded = try FixtureLoader.decode(AnthropicOAuthUsageResponse.self, from: "Anthropic/oauth_usage_basic")

        let fiveHour = try XCTUnwrap(decoded.fiveHour)
        XCTAssertEqual(fiveHour.utilization ?? -1, 0.42, accuracy: 0.001)
        XCTAssertEqual(fiveHour.resetsAt, "2026-05-01T18:00:00Z")

        let sevenDay = try XCTUnwrap(decoded.sevenDay)
        XCTAssertEqual(sevenDay.utilization ?? -1, 0.18, accuracy: 0.001)
        XCTAssertEqual(sevenDay.resetsAt, "2026-05-08T18:00:00Z")

        let sevenDayOpus = try XCTUnwrap(decoded.sevenDayOpus)
        XCTAssertEqual(sevenDayOpus.utilization ?? -1, 0.05, accuracy: 0.001)

        XCTAssertNil(decoded.extraUsage)
    }

    /// Verifies extra_usage fields decode correctly.
    func testUsageWithExtraDecodes() throws {
        let decoded = try FixtureLoader.decode(
            AnthropicOAuthUsageResponse.self,
            from: "Anthropic/oauth_usage_with_extra"
        )

        let fiveHour = try XCTUnwrap(decoded.fiveHour)
        XCTAssertEqual(fiveHour.utilization ?? -1, 0.65, accuracy: 0.001)

        let sevenDay = try XCTUnwrap(decoded.sevenDay)
        XCTAssertEqual(sevenDay.utilization ?? -1, 0.31, accuracy: 0.001)

        let extra = try XCTUnwrap(decoded.extraUsage)
        XCTAssertEqual(extra.isEnabled, true)
        XCTAssertEqual(extra.monthlyLimit ?? -1, 100.0, accuracy: 0.001)
        XCTAssertEqual(extra.usedCredits ?? -1, 12.3, accuracy: 0.001)
        XCTAssertEqual(extra.utilization ?? -1, 0.123, accuracy: 0.001)
        XCTAssertEqual(extra.currency, "usd")
    }

    /// Verifies that unknown keys (omelette, cowork, claude_design, etc.) don't throw.
    func testUsageWithUnknownKeysDoesNotThrow() throws {
        let decoded = try FixtureLoader.decode(
            AnthropicOAuthUsageResponse.self,
            from: "Anthropic/oauth_usage_unknown_keys"
        )

        // Known windows are still decoded correctly.
        let fiveHour = try XCTUnwrap(decoded.fiveHour)
        XCTAssertEqual(fiveHour.utilization ?? -1, 0.30, accuracy: 0.001)

        let sevenDay = try XCTUnwrap(decoded.sevenDay)
        XCTAssertEqual(sevenDay.utilization ?? -1, 0.12, accuracy: 0.001)

        // Unknown fields are silently ignored — no throw.
        XCTAssertNil(decoded.extraUsage)
    }

    /// Verifies the Anthropic unauthorized fixture preserves stable error fields.
    func testUnauthorizedFixtureLoads() throws {
        let data = try FixtureLoader.loadData("Anthropic/unauthorized")
        let object = try JSONSerialization.jsonObject(with: data)

        let dictionary = try XCTUnwrap(object as? [String: Any])
        let error = try XCTUnwrap(dictionary["error"] as? [String: Any])
        XCTAssertEqual(error["type"] as? String, "authentication_error")
        XCTAssertEqual(error["message"] as? String, "invalid x-api-key")
    }
}
