@testable import iCodexBarCore
import XCTest

// MARK: - Decoder Tests

final class CodexUsageAPITests: XCTestCase {
    private let decoder = JSONDecoder()

    func testDecodesFullResponse() throws {
        let data = try FixtureLoader.loadData("Codex/usage_full")
        let response = try decoder.decode(CodexUsageResponse.self, from: data)

        XCTAssertEqual(response.planType, "plus")

        let primary = try XCTUnwrap(response.rateLimit?.primaryWindow)
        XCTAssertEqual(primary.usedPercent, 42, accuracy: 0.001)
        XCTAssertEqual(primary.resetAt, 1_746_122_400)
        XCTAssertEqual(primary.limitWindowSeconds, 18000)

        let secondary = try XCTUnwrap(response.rateLimit?.secondaryWindow)
        XCTAssertEqual(secondary.usedPercent, 7, accuracy: 0.001)
        XCTAssertEqual(secondary.limitWindowSeconds, 604_800)

        let credits = try XCTUnwrap(response.credits)
        XCTAssertTrue(credits.hasCredits)
        XCTAssertFalse(credits.unlimited)
        XCTAssertEqual(try XCTUnwrap(credits.balance), 12.34, accuracy: 0.001)
    }

    func testDecodesPartialResponse() throws {
        let data = try FixtureLoader.loadData("Codex/usage_partial")
        let response = try decoder.decode(CodexUsageResponse.self, from: data)

        XCTAssertNil(response.planType)

        let primary = try XCTUnwrap(response.rateLimit?.primaryWindow)
        XCTAssertEqual(primary.usedPercent, 60, accuracy: 0.001)
        XCTAssertEqual(primary.limitWindowSeconds, 18000)

        XCTAssertNil(response.rateLimit?.secondaryWindow)
        XCTAssertNil(response.credits)
    }

    func testTolerantOfUnknownKeys() throws {
        let data = try FixtureLoader.loadData("Codex/usage_unknown_keys")
        // Must not throw even though the JSON has unknown top-level and nested keys.
        XCTAssertNoThrow(try decoder.decode(CodexUsageResponse.self, from: data))

        let response = try decoder.decode(CodexUsageResponse.self, from: data)
        XCTAssertEqual(response.planType, "pro")

        let primary = try XCTUnwrap(response.rateLimit?.primaryWindow)
        XCTAssertEqual(primary.usedPercent, 10, accuracy: 0.001)

        let credits = try XCTUnwrap(response.credits)
        XCTAssertTrue(credits.unlimited)
        XCTAssertFalse(credits.hasCredits)
        XCTAssertNil(credits.balance)
    }
}

// MARK: - Network Tests

final class CodexUsageAPINetworkTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test401ThrowsUnauthorized() async throws {
        let url = try XCTUnwrap(URL(string: "https://chatgpt.com"))
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 401), Data())
        }

        let api = CodexUsageAPI(session: makeMockSession())
        let credentials = CodexAuthCredentials(accessToken: "expired-token", accountId: nil)

        do {
            _ = try await api.fetchUsage(credentials: credentials)
            XCTFail("Expected CodexUsageError.unauthorized")
        } catch CodexUsageError.unauthorized {
            // Expected
        }
    }

    func test403ThrowsUnauthorized() async throws {
        let url = try XCTUnwrap(URL(string: "https://chatgpt.com"))
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 403), Data())
        }

        let api = CodexUsageAPI(session: makeMockSession())
        let credentials = CodexAuthCredentials(accessToken: "bad-token", accountId: nil)

        do {
            _ = try await api.fetchUsage(credentials: credentials)
            XCTFail("Expected CodexUsageError.unauthorized")
        } catch CodexUsageError.unauthorized {
            // Expected
        }
    }

    func test500ThrowsServerError() async throws {
        let url = try XCTUnwrap(URL(string: "https://chatgpt.com"))
        let body = Data("Internal Server Error".utf8)
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 500), body)
        }

        let api = CodexUsageAPI(session: makeMockSession())
        let credentials = CodexAuthCredentials(accessToken: "valid-token", accountId: nil)

        do {
            _ = try await api.fetchUsage(credentials: credentials)
            XCTFail("Expected CodexUsageError.serverError")
        } catch let CodexUsageError.serverError(code, _) {
            XCTAssertEqual(code, 500)
        }
    }

    func testSuccessDecodesResponse() async throws {
        let url = try XCTUnwrap(URL(string: "https://chatgpt.com"))
        let json = """
        {"plan_type":"pro","rate_limit":{"primary_window":{"used_percent":33,"reset_at":1746122400,"limit_window_seconds":18000}}}
        """
        MockURLProtocol.requestHandler = { _ in
            (makeResponse(url: url, statusCode: 200), Data(json.utf8))
        }

        let api = CodexUsageAPI(session: makeMockSession())
        let credentials = CodexAuthCredentials(accessToken: "valid-token", accountId: "acct-123")
        let response = try await api.fetchUsage(credentials: credentials)

        XCTAssertEqual(response.planType, "pro")
        XCTAssertEqual(response.rateLimit?.primaryWindow?.usedPercent ?? 0, 33, accuracy: 0.001)
    }
}

// MARK: - Snapshot conversion

final class CodexUsageResponseSnapshotTests: XCTestCase {
    func testMapsToProviderUsageSnapshot() throws {
        let data = try FixtureLoader.loadData("Codex/usage_full")
        let response = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
        let snapshot = response.toSnapshot(updatedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(snapshot.provider, .codexCLI)
        XCTAssertEqual(snapshot.primary?.usedPercent ?? 0, 42, accuracy: 0.001)
        XCTAssertEqual(snapshot.secondary?.usedPercent ?? 0, 7, accuracy: 0.001)
        XCTAssertEqual(snapshot.balance ?? 0, 12.34, accuracy: 0.001)
    }
}

// MARK: - Helpers (reuse the existing mock helpers shape)

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}
