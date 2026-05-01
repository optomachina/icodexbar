@testable import iCodexBarCore
import XCTest

/// Fixture-backed decoder coverage for Anthropic responses.
final class AnthropicDecoderTests: XCTestCase {
    /// Verifies the Anthropic OAuth usage fixture decodes quota fields.
    func testOAuthUsageBasicDecodesUsage() throws {
        let decoded = try FixtureLoader.decode(AnthropicOAuthUsageResponse.self, from: "Anthropic/oauth_usage_basic")

        XCTAssertEqual(decoded.sevenDay, 47_000)
        XCTAssertEqual(decoded.rateLimitTier, "build")
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
