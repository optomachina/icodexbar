@testable import iCodexBarCore
import XCTest

final class ProviderTests: XCTestCase {
    // MARK: - Raw Value Tests

    func testProviderRawValues() {
        XCTAssertEqual(Provider.openAI.rawValue, "openai")
        XCTAssertEqual(Provider.anthropic.rawValue, "anthropic")
        XCTAssertEqual(Provider.openRouter.rawValue, "openrouter")
    }

    func testProviderAllCases() {
        XCTAssertEqual(Provider.allCases.count, 3)
        XCTAssertTrue(Provider.allCases.contains(.openAI))
        XCTAssertTrue(Provider.allCases.contains(.anthropic))
        XCTAssertTrue(Provider.allCases.contains(.openRouter))
    }

    // MARK: - Display Name Tests

    func testProviderDisplayNames() {
        XCTAssertEqual(Provider.openAI.displayName, "OpenAI")
        XCTAssertEqual(Provider.anthropic.displayName, "Anthropic")
        XCTAssertEqual(Provider.openRouter.displayName, "OpenRouter")
    }

    // MARK: - ID Tests

    func testProviderID() {
        XCTAssertEqual(Provider.openAI.id, "openai")
        XCTAssertEqual(Provider.anthropic.id, "anthropic")
        XCTAssertEqual(Provider.openRouter.id, "openrouter")
    }

    // MARK: - Keychain Service Tests

    func testProviderKeychainService() {
        XCTAssertEqual(Provider.openAI.keychainService, "com.icodexbar.keychain.openai")
        XCTAssertEqual(Provider.anthropic.keychainService, "com.icodexbar.keychain.anthropic")
        XCTAssertEqual(Provider.openRouter.keychainService, "com.icodexbar.keychain.openrouter")
    }

    // MARK: - Icon Name Tests

    func testProviderIconNames() {
        XCTAssertEqual(Provider.openAI.iconName, "brain")
        XCTAssertEqual(Provider.anthropic.iconName, "cpu")
        XCTAssertEqual(Provider.openRouter.iconName, "network")
    }

    // MARK: - Codable Tests

    func testProviderCodable() throws {
        let provider = Provider.openAI
        let data = try JSONEncoder().encode(provider)
        let decoded = try JSONDecoder().decode(Provider.self, from: data)
        XCTAssertEqual(decoded, provider)
    }

    func testProviderDecodingFromRawValue() throws {
        let json = "\"openrouter\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Provider.self, from: json)
        XCTAssertEqual(decoded, .openRouter)
    }
}
