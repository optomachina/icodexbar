import XCTest
@testable import iCodexBar

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Test Helpers

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

// MARK: - OpenAI Tests

final class OpenAIUsageAPITests: XCTestCase {

    func testParsesDailyCost() async throws {
        let json = """
        {"data": [{"n_tokens_total": 12000, "cost": 1.45, "date": "2026-04-01",
                   "n_context_tokens_total": 10000, "n_generated_tokens_total": 2000}]}
        """
        let url = URL(string: "https://api.openai.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(json.utf8))
        }

        let api = OpenAIUsageAPI(session: makeMockSession())
        let snapshot = try await api.fetchUsage(apiKey: "sk-test-key-valid")

        XCTAssertEqual(snapshot.provider, .openAI)
        XCTAssertEqual(snapshot.totalTokens, 12000)
        XCTAssertEqual(snapshot.totalCostUSD, 1.45, accuracy: 0.001)
    }

    func testParsesEmptyData() async throws {
        let json = """{"data": []}"""
        let url = URL(string: "https://api.openai.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(json.utf8))
        }

        let api = OpenAIUsageAPI(session: makeMockSession())
        let snapshot = try await api.fetchUsage(apiKey: "sk-test-key-valid")

        XCTAssertEqual(snapshot.totalTokens, 0)
        XCTAssertEqual(snapshot.totalCostUSD, 0.0, accuracy: 0.001)
    }

    func test401ThrowsInvalidCredentials() async throws {
        let url = URL(string: "https://api.openai.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 401), Data())
        }

        let api = OpenAIUsageAPI(session: makeMockSession())
        do {
            _ = try await api.fetchUsage(apiKey: "sk-bad-key-value")
            XCTFail("Expected invalidCredentials error")
        } catch ProviderAPIError.invalidCredentials {
            // Expected
        }
    }

    func test404ThrowsDescriptiveError() async throws {
        let url = URL(string: "https://api.openai.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 404), Data())
        }

        let api = OpenAIUsageAPI(session: makeMockSession())
        do {
            _ = try await api.fetchUsage(apiKey: "sk-test-key-valid")
            XCTFail("Expected apiError")
        } catch ProviderAPIError.apiError(let code, let message) {
            XCTAssertEqual(code, 404)
            XCTAssertTrue(message.contains("legacy org API key"), "Expected descriptive 404 message, got: \(message)")
        }
    }
}

// MARK: - OpenRouter Tests

final class OpenRouterUsageAPITests: XCTestCase {

    func testParsesBalance() async throws {
        let creditsJSON = """
        {"data": {"total_credits": 10.0, "total_usage": 3.80, "balance": 6.20}}
        """
        let url = URL(string: "https://openrouter.ai")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(creditsJSON.utf8))
        }

        let api = OpenRouterUsageAPI(session: makeMockSession())
        let snapshot = try await api.fetchUsage(apiKey: "sk-or-test-key-valid")

        XCTAssertEqual(snapshot.provider, .openRouter)
        XCTAssertEqual(snapshot.balance, 6.20, accuracy: 0.001)
        XCTAssertEqual(snapshot.totalCostUSD, 3.80, accuracy: 0.001)
    }

    func testZeroTotalCreditsGivesZeroPercent() async throws {
        let creditsJSON = """
        {"data": {"total_credits": 0.0, "total_usage": 0.0, "balance": 0.0}}
        """
        let url = URL(string: "https://openrouter.ai")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(creditsJSON.utf8))
        }

        let api = OpenRouterUsageAPI(session: makeMockSession())
        let snapshot = try await api.fetchUsage(apiKey: "sk-or-test-key-valid")

        XCTAssertEqual(snapshot.primary?.usedPercent ?? -1, 0, accuracy: 0.001)
    }
}

// MARK: - Anthropic OAuth Tests

final class AnthropicUsageAPITests: XCTestCase {

    func testParsesSevenDayAndTier() async throws {
        let json = """
        {"seven_day": 47000, "five_hour": 1200, "rate_limit_tier": "build"}
        """
        let url = URL(string: "https://api.anthropic.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(json.utf8))
        }

        let api = AnthropicUsageAPI(session: makeMockSession())
        let snapshot = try await api.fetchUsage(apiKey: "oauth-test-token-valid")

        XCTAssertEqual(snapshot.provider, .anthropic)
        XCTAssertEqual(snapshot.totalTokens, 47000)
        XCTAssertEqual(snapshot.totalCostUSD, 0.0, accuracy: 0.001)
        XCTAssertTrue(snapshot.primary?.resetDescription?.contains("build") ?? false,
                      "Expected rate limit tier in resetDescription")
    }

    func testMissingRateLimitTierShowsUnknown() async throws {
        let json = """{"seven_day": 1000}"""
        let url = URL(string: "https://api.anthropic.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(json.utf8))
        }

        let api = AnthropicUsageAPI(session: makeMockSession())
        let snapshot = try await api.fetchUsage(apiKey: "oauth-test-token-valid")

        XCTAssertTrue(snapshot.primary?.resetDescription?.contains("unknown") ?? false)
    }

    func test401ThrowsDescriptiveError() async throws {
        let url = URL(string: "https://api.anthropic.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 401), Data())
        }

        let api = AnthropicUsageAPI(session: makeMockSession())
        do {
            _ = try await api.fetchUsage(apiKey: "bad-oauth-token")
            XCTFail("Expected apiError")
        } catch ProviderAPIError.apiError(let code, let message) {
            XCTAssertEqual(code, 401)
            XCTAssertTrue(message.contains("OAuth token"), "Expected OAuth token guidance, got: \(message)")
        }
    }

    func test404ThrowsDescriptiveError() async throws {
        let url = URL(string: "https://api.anthropic.com")!
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 404), Data())
        }

        let api = AnthropicUsageAPI(session: makeMockSession())
        do {
            _ = try await api.fetchUsage(apiKey: "oauth-test-token-valid")
            XCTFail("Expected apiError")
        } catch ProviderAPIError.apiError(let code, let message) {
            XCTAssertEqual(code, 404)
            XCTAssertTrue(message.contains("Demo Mode"), "Expected Demo Mode guidance in 404 message, got: \(message)")
        }
    }
}
