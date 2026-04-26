@testable import iCodexBarCore
import XCTest

final class AnthropicDecoderTests: XCTestCase {
    func testOAuthUsageBasicDecodesUsage() throws {
        let decoded = try FixtureLoader.decode(AnthropicOAuthUsageResponse.self, from: "Anthropic/oauth_usage_basic")

        XCTAssertEqual(decoded.sevenDay, 47_000)
        XCTAssertEqual(decoded.rateLimitTier, "build")
    }

    func testUnauthorizedFixtureLoads() throws {
        let data = try FixtureLoader.loadData("Anthropic/unauthorized")
        let object = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(object is [String: Any])
    }
}
