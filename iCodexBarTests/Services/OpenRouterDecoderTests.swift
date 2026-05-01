@testable import iCodexBarCore
import XCTest

/// Fixture-backed decoder coverage for OpenRouter responses.
final class OpenRouterDecoderTests: XCTestCase {
    /// Verifies the baseline OpenRouter credits response decodes monetary fields.
    func testCreditsBasicDecodes() throws {
        let decoded = try FixtureLoader.decode(OpenRouterCredits.self, from: "OpenRouter/credits_basic")

        XCTAssertEqual(decoded.data.totalCredits, 10.0)
        XCTAssertEqual(decoded.data.totalUsage, 3.25)
        XCTAssertEqual(decoded.data.balance, 6.75)
    }

    /// Verifies zero-credit OpenRouter responses decode without nil substitution.
    func testCreditsZeroDecodes() throws {
        let decoded = try FixtureLoader.decode(OpenRouterCredits.self, from: "OpenRouter/credits_zero")

        XCTAssertEqual(decoded.data.totalCredits, 0.0)
        XCTAssertEqual(decoded.data.totalUsage, 0.0)
        XCTAssertEqual(decoded.data.balance, 0.0)
    }

    /// Verifies OpenRouter key information decodes optional limit metadata.
    func testKeyInfoWithLimitDecodes() throws {
        let decoded = try FixtureLoader.decode(OpenRouterKeyInfo.self, from: "OpenRouter/key_info_with_limit")

        XCTAssertEqual(decoded.limit, 5.0)
        XCTAssertEqual(decoded.usage, 1.5)

        let rateLimit = try XCTUnwrap(decoded.rateLimit)
        XCTAssertEqual(rateLimit.requests, 200)
        XCTAssertEqual(rateLimit.interval, "10s")
    }

    /// Verifies null OpenRouter key fields remain nil after decoding.
    func testKeyInfoNoLimitDecodesNullsAsNil() throws {
        let decoded = try FixtureLoader.decode(OpenRouterKeyInfo.self, from: "OpenRouter/key_info_no_limit")

        XCTAssertNil(decoded.limit)
        XCTAssertNil(decoded.usage)
        XCTAssertNil(decoded.rateLimit)
    }

    /// Verifies the OpenRouter rate-limit fixture preserves stable error fields.
    func testRateLimitedFixtureLoads() throws {
        let data = try FixtureLoader.loadData("OpenRouter/rate_limited")
        let object = try JSONSerialization.jsonObject(with: data)

        let dictionary = try XCTUnwrap(object as? [String: Any])
        let error = try XCTUnwrap(dictionary["error"] as? [String: Any])
        XCTAssertEqual(error["message"] as? String, "Rate limit exceeded")
        XCTAssertEqual(error["code"] as? Int, 429)
    }
}
