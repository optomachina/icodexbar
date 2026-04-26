@testable import iCodexBarCore
import XCTest

final class OpenRouterDecoderTests: XCTestCase {
    func testCreditsBasicDecodes() throws {
        let decoded = try FixtureLoader.decode(OpenRouterCredits.self, from: "OpenRouter/credits_basic")

        XCTAssertEqual(decoded.data.totalCredits, 10.0)
        XCTAssertEqual(decoded.data.totalUsage, 3.25)
        XCTAssertEqual(decoded.data.balance, 6.75)
    }

    func testCreditsZeroDecodes() throws {
        let decoded = try FixtureLoader.decode(OpenRouterCredits.self, from: "OpenRouter/credits_zero")

        XCTAssertEqual(decoded.data.totalCredits, 0.0)
        XCTAssertEqual(decoded.data.totalUsage, 0.0)
        XCTAssertEqual(decoded.data.balance, 0.0)
    }

    func testKeyInfoWithLimitDecodes() throws {
        let decoded = try FixtureLoader.decode(OpenRouterKeyInfo.self, from: "OpenRouter/key_info_with_limit")

        XCTAssertEqual(decoded.limit, 5.0)
        XCTAssertEqual(decoded.usage, 1.5)

        let rateLimit = try XCTUnwrap(decoded.rateLimit)
        XCTAssertEqual(rateLimit.requests, 200)
        XCTAssertEqual(rateLimit.interval, "10s")
    }

    func testKeyInfoNoLimitDecodesNullsAsNil() throws {
        let decoded = try FixtureLoader.decode(OpenRouterKeyInfo.self, from: "OpenRouter/key_info_no_limit")

        XCTAssertNil(decoded.limit)
        XCTAssertNil(decoded.usage)
        XCTAssertNil(decoded.rateLimit)
    }

    func testRateLimitedFixtureLoads() throws {
        let data = try FixtureLoader.loadData("OpenRouter/rate_limited")
        let object = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(object is [String: Any])
    }
}
