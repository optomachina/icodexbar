@testable import iCodexBarCore
import XCTest

final class UsageAPIServiceTests: XCTestCase {
    func testAnthropicMessageResponseDecodesUsageFromBody() throws {
        let json = """
        {"id":"msg_01abc","type":"message","role":"assistant","model":"claude-haiku-4-5-20251001","content":[{"type":"text","text":"ok"}],"stop_reason":"end_turn","usage":{"input_tokens":12,"output_tokens":5}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let decoded = try JSONDecoder().decode(AnthropicMessageResponse.self, from: data)

        XCTAssertEqual(decoded.usage.inputTokens, 12)
        XCTAssertEqual(decoded.usage.outputTokens, 5)
    }

    func testOpenAICostsResponseParsesDailyCostWithoutTokens() throws {
        let json = """
        {"object":"page","data":[{"object":"bucket","start_time":1714003200,"end_time":1714089600,"results":[{"object":"organization.costs.result","amount":{"value":1.2345,"currency":"usd"},"line_item":null,"project_id":null}]}],"has_more":false,"next_page":null}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
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
