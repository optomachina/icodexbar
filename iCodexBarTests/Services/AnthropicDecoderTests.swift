@testable import iCodexBarCore
import XCTest

final class AnthropicDecoderTests: XCTestCase {
    func testMessageBasicDecodesUsage() throws {
        let decoded = try FixtureLoader.decode(AnthropicMessageResponse.self, from: "Anthropic/message_basic")

        XCTAssertEqual(decoded.usage.inputTokens, 12)
        XCTAssertEqual(decoded.usage.outputTokens, 5)
    }

    func testUnauthorizedFixtureLoads() throws {
        let data = try FixtureLoader.loadData("Anthropic/unauthorized")
        let object = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(object is [String: Any])
    }
}
