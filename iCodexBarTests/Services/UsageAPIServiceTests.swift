@testable import iCodexBarCore
import XCTest

final class UsageAPIServiceTests: XCTestCase {
    func testAnthropicMessageResponseDecodesUsageFromBody() throws {
        let data = try FixtureLoader.loadData("Anthropic/message_basic")

        let decoded = try JSONDecoder().decode(AnthropicMessageResponse.self, from: data)

        XCTAssertEqual(decoded.usage.inputTokens, 12)
        XCTAssertEqual(decoded.usage.outputTokens, 5)
    }

    func testOpenAICostsResponseParsesDailyCostWithoutTokens() throws {
        let data = try FixtureLoader.loadData("OpenAI/costs_basic")
        let decoded = try JSONDecoder().decode(OpenAICostsResponse.self, from: data)

        let snapshot = OpenAIUsageAPI().parseReport(
            decoded,
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(snapshot.dailyUsage.count, 1)
        XCTAssertEqual(snapshot.dailyUsage.first?.date, "2024-04-25")
        XCTAssertEqual(snapshot.dailyUsage.first?.costUSD, 1.2345)
        XCTAssertNil(snapshot.dailyUsage.first?.totalTokens)
        XCTAssertNil(snapshot.totalTokens)
        XCTAssertEqual(snapshot.totalCostUSD, 1.2345)
    }
}
