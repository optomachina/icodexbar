@testable import iCodexBar
import XCTest

final class KeychainServiceTests: XCTestCase {
    private var keychain: KeychainService!

    override func setUp() async throws {
        try await super.setUp()
        keychain = KeychainService.shared
    }

    override func tearDown() async throws {
        // Clean up any test keys
        for provider in Provider.allCases {
            try? await keychain.delete(key: provider.rawValue)
        }
        try await super.tearDown()
    }

    // MARK: - Save and Retrieve Tests

    func testSaveAndRetrieve() async throws {
        let testKey = "test_openai"
        let testValue = "sk-test-key-12345"

        try await keychain.save(key: testKey, value: testValue)
        let retrieved = try await keychain.get(key: testKey)

        XCTAssertEqual(retrieved, testValue)

        // Cleanup
        try await keychain.delete(key: testKey)
    }

    func testSaveOverwrites() async throws {
        let testKey = "test_overwrite"

        try await keychain.save(key: testKey, value: "first-value")
        try await keychain.save(key: testKey, value: "second-value")

        let retrieved = try await keychain.get(key: testKey)
        XCTAssertEqual(retrieved, "second-value")

        // Cleanup
        try await keychain.delete(key: testKey)
    }

    // MARK: - Delete Tests

    func testDelete() async throws {
        let testKey = "test_delete"
        try await keychain.save(key: testKey, value: "value")

        try await keychain.delete(key: testKey)

        do {
            _ = try await keychain.get(key: testKey)
            XCTFail("Should have thrown notFound error")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - Exists Tests

    func testExistsTrue() async throws {
        let testKey = "test_exists_true"
        try await keychain.save(key: testKey, value: "value")

        let exists = await keychain.exists(key: testKey)
        XCTAssertTrue(exists)

        try await keychain.delete(key: testKey)
    }

    func testExistsFalse() async {
        let exists = await keychain.exists(key: "nonexistent_key")
        XCTAssertFalse(exists)
    }

    // MARK: - Stored Providers Tests

    func testStoredProviders() async throws {
        // Clean slate
        for provider in Provider.allCases {
            try? await keychain.delete(key: provider.rawValue)
        }

        // Add one provider
        try await keychain.save(key: Provider.openAI.rawValue, value: "test-key")

        let stored = await keychain.storedProviders()
        XCTAssertTrue(stored.contains(.openAI))
        XCTAssertFalse(stored.contains(.anthropic))

        // Cleanup
        try await keychain.delete(key: Provider.openAI.rawValue)
    }

    // MARK: - Error Cases

    func testGetNonexistentThrowsNotFound() async throws {
        do {
            _ = try await keychain.get(key: "nonexistent_key_\(UUID().uuidString)")
            XCTFail("Should have thrown notFound error")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .notFound)
        }
    }

    func testSaveEmptyKeyThrowsInvalidInput() async throws {
        do {
            try await keychain.save(key: "", value: "value")
            XCTFail("Should have thrown invalidInput error")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .invalidInput)
        }
    }

    func testSaveEmptyValueThrowsInvalidInput() async throws {
        do {
            try await keychain.save(key: "test_key", value: "")
            XCTFail("Should have thrown invalidInput error")
        } catch let error as KeychainError {
            XCTAssertEqual(error, .invalidInput)
        }
    }
}
