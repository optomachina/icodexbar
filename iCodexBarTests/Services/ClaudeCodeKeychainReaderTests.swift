@testable import iCodexBarCore
import XCTest

final class ClaudeCodeKeychainReaderTests: XCTestCase {
    // MARK: - Parse

    func testParsesFullCredentialBlob() throws {
        let json = """
        {
          "claudeAiOauth": {
            "accessToken": "tok-abc",
            "refreshToken": "ref-xyz",
            "expiresAt": 1778017579766,
            "scopes": ["user:inference", "user:profile"],
            "subscriptionType": "max",
            "rateLimitTier": "default_claude_max_20x"
          },
          "mcpOAuth": {}
        }
        """
        let creds = try ClaudeCodeKeychainReader.parse(data: Data(json.utf8))
        XCTAssertEqual(creds.accessToken, "tok-abc")
        XCTAssertEqual(creds.refreshToken, "ref-xyz")
        XCTAssertEqual(creds.subscriptionType, "max")
        XCTAssertEqual(creds.rateLimitTier, "default_claude_max_20x")
        XCTAssertNotNil(creds.expiresAt)
    }

    func testThrowsWhenRootIsNotJSONObject() {
        XCTAssertThrowsError(try ClaudeCodeKeychainReader.parse(data: Data("[]".utf8)))
        XCTAssertThrowsError(try ClaudeCodeKeychainReader.parse(data: Data("garbage".utf8)))
    }

    func testThrowsWhenClaudeAiOauthMissing() {
        let json = #"{"mcpOAuth":{}}"#
        XCTAssertThrowsError(try ClaudeCodeKeychainReader.parse(data: Data(json.utf8))) { err in
            guard case ClaudeCodeKeychainError.malformed = err else {
                return XCTFail("Expected .malformed, got \(err)")
            }
        }
    }

    func testThrowsWhenAccessTokenMissingOrEmpty() {
        let json1 = #"{"claudeAiOauth":{"refreshToken":"x"}}"#
        XCTAssertThrowsError(try ClaudeCodeKeychainReader.parse(data: Data(json1.utf8)))

        let json2 = #"{"claudeAiOauth":{"accessToken":""}}"#
        XCTAssertThrowsError(try ClaudeCodeKeychainReader.parse(data: Data(json2.utf8)))
    }

    func testTolerantOfMissingOptionalFields() throws {
        let json = #"{"claudeAiOauth":{"accessToken":"tok-only"}}"#
        let creds = try ClaudeCodeKeychainReader.parse(data: Data(json.utf8))
        XCTAssertEqual(creds.accessToken, "tok-only")
        XCTAssertNil(creds.refreshToken)
        XCTAssertNil(creds.subscriptionType)
        XCTAssertNil(creds.rateLimitTier)
        XCTAssertNil(creds.expiresAt)
    }

    // MARK: - Plan inference

    func testInferredPlanFromTier() {
        XCTAssertEqual(ClaudeCodePlan(rateLimitTier: "default_claude_max_20x"), .max20x)
        XCTAssertEqual(ClaudeCodePlan(rateLimitTier: "default_claude_max_5x"), .max5x)
        XCTAssertEqual(ClaudeCodePlan(rateLimitTier: "default_claude_pro"), .pro)
        // Case-insensitive
        XCTAssertEqual(ClaudeCodePlan(rateLimitTier: "DEFAULT_CLAUDE_MAX_20X"), .max20x)
        // Unknown
        XCTAssertNil(ClaudeCodePlan(rateLimitTier: "experimental_quantum"))
        XCTAssertNil(ClaudeCodePlan(rateLimitTier: nil))
    }

    func testCredentialsInferredPlanFallsBackToMax20x() {
        let creds = ClaudeCodeCredentials(accessToken: "tok", rateLimitTier: nil)
        XCTAssertEqual(creds.inferredPlan, .max20x)

        let credsUnknown = ClaudeCodeCredentials(accessToken: "tok", rateLimitTier: "weird")
        XCTAssertEqual(credsUnknown.inferredPlan, .max20x)

        let credsPro = ClaudeCodeCredentials(accessToken: "tok", rateLimitTier: "default_claude_pro")
        XCTAssertEqual(credsPro.inferredPlan, .pro)
    }
}
