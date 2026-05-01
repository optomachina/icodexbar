@testable import iCodexBarCore
import XCTest

final class CodexAuthReaderTests: XCTestCase {
    // MARK: - Helpers

    private func makeTempCodexHome(_ configure: (URL) throws -> Void) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexAuthReaderTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try configure(dir)
        return dir
    }

    // MARK: - Auth reader tests

    func testReadsValidAuthJSON() throws {
        let home = try makeTempCodexHome { dir in
            let auth = """
            {
              "auth_mode": "chatgpt",
              "OPENAI_API_KEY": null,
              "tokens": {
                "access_token": "eyJtest123",
                "account_id": "acct-abc",
                "refresh_token": "refresh-xyz"
              }
            }
            """
            try auth.data(using: .utf8)!
                .write(to: dir.appendingPathComponent("auth.json"))
        }

        let credentials = try CodexAuthReader.read(env: ["CODEX_HOME": home.path])
        XCTAssertEqual(credentials.accessToken, "eyJtest123")
        XCTAssertEqual(credentials.accountId, "acct-abc")
    }

    func testHandlesMissingAuthFile() throws {
        let home = try makeTempCodexHome { _ in
            // Don't write anything
        }

        do {
            _ = try CodexAuthReader.read(env: ["CODEX_HOME": home.path])
            XCTFail("Expected CodexAuthError.authFileMissing")
        } catch CodexAuthError.authFileMissing {
            // Expected
        }
    }

    func testParsesAuthJSONWithoutAccountId() throws {
        let home = try makeTempCodexHome { dir in
            let auth = """
            {
              "tokens": {
                "access_token": "eyJnoAccountId"
              }
            }
            """
            try auth.data(using: .utf8)!
                .write(to: dir.appendingPathComponent("auth.json"))
        }

        let credentials = try CodexAuthReader.read(env: ["CODEX_HOME": home.path])
        XCTAssertEqual(credentials.accessToken, "eyJnoAccountId")
        XCTAssertNil(credentials.accountId)
    }

    func testMalformedJSONThrowsAuthFileMalformed() throws {
        let home = try makeTempCodexHome { dir in
            try "not json at all".data(using: .utf8)!
                .write(to: dir.appendingPathComponent("auth.json"))
        }

        do {
            _ = try CodexAuthReader.read(env: ["CODEX_HOME": home.path])
            XCTFail("Expected CodexAuthError.authFileMalformed")
        } catch CodexAuthError.authFileMalformed {
            // Expected
        }
    }

    func testMissingTokensObjectThrowsAuthFileMalformed() throws {
        let home = try makeTempCodexHome { dir in
            let auth = #"{"auth_mode":"chatgpt"}"#
            try auth.data(using: .utf8)!
                .write(to: dir.appendingPathComponent("auth.json"))
        }

        do {
            _ = try CodexAuthReader.read(env: ["CODEX_HOME": home.path])
            XCTFail("Expected CodexAuthError.authFileMalformed or noAccessToken")
        } catch CodexAuthError.authFileMalformed {
            // Expected
        } catch CodexAuthError.noAccessToken {
            // Also acceptable
        }
    }

    // MARK: - Base URL tests

    func testParsesBaseURLOverride() throws {
        let home = try makeTempCodexHome { dir in
            let toml = #"chatgpt_base_url = "https://example.com/backend-api""#
            try toml.data(using: .utf8)!
                .write(to: dir.appendingPathComponent("config.toml"))
        }

        let url = CodexAuthReader.chatGPTBaseURL(env: ["CODEX_HOME": home.path])
        XCTAssertEqual(url.absoluteString, "https://example.com/backend-api")
    }

    func testDefaultBaseURL() throws {
        let home = try makeTempCodexHome { _ in
            // No config.toml
        }

        let url = CodexAuthReader.chatGPTBaseURL(env: ["CODEX_HOME": home.path])
        XCTAssertEqual(url.absoluteString, "https://chatgpt.com/backend-api")
    }

    func testBaseURLWithoutPathGetsSuffix() throws {
        let home = try makeTempCodexHome { dir in
            let toml = #"chatgpt_base_url = "https://chatgpt.com""#
            try toml.data(using: .utf8)!
                .write(to: dir.appendingPathComponent("config.toml"))
        }

        let url = CodexAuthReader.chatGPTBaseURL(env: ["CODEX_HOME": home.path])
        XCTAssertTrue(
            url.absoluteString.contains("/backend-api"),
            "Expected /backend-api appended, got: \(url.absoluteString)"
        )
    }

    func testParseChatGPTBaseURLFromTomlContents() {
        let contents = """
        # comment line
        some_other_key = "value"
        chatgpt_base_url = "https://my.proxy.example.com/backend-api"
        """
        let result = CodexAuthReader.parseChatGPTBaseURL(from: contents)
        XCTAssertEqual(result, "https://my.proxy.example.com/backend-api")
    }

    func testParseChatGPTBaseURLMissingKey() {
        let contents = """
        some_other_key = "value"
        """
        let result = CodexAuthReader.parseChatGPTBaseURL(from: contents)
        XCTAssertNil(result)
    }
}
