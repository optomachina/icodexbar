import Foundation
import Security

// MARK: - Keychain Error

public enum KeychainError: Error, LocalizedError, Equatable {
    case duplicate
    case notFound
    case unexpectedStatus(OSStatus)
    case encodingError
    case invalidInput

    public var errorDescription: String? {
        switch self {
        case .duplicate:
            "An item with this key already exists"
        case .notFound:
            "Item not found in Keychain"
        case let .unexpectedStatus(status):
            "Keychain error: \(status)"
        case .encodingError:
            "Failed to encode or decode data"
        case .invalidInput:
            "Invalid input"
        }
    }
}

// MARK: - Keychain Service

/// Secure storage for API keys using iOS Keychain
public final class KeychainService {
    public static let shared = KeychainService()

    private let accessGroup: String? = nil // Set to App Group keychain group if sharing between app + widget

    private init() {}

    // MARK: - Public API

    /// Save an API key for a provider
    public func save(key: String, value: String) throws {
        guard !key.isEmpty, !value.isEmpty else {
            throw KeychainError.invalidInput
        }
        let service = keychainService(for: key)
        try save(value, for: service.key, in: service.service)
    }

    /// Retrieve an API key for a provider
    public func get(key: String) throws -> String {
        guard !key.isEmpty else { throw KeychainError.invalidInput }
        let service = keychainService(for: key)
        return try retrieve(for: service.key, in: service.service)
    }

    /// Delete an API key for a provider
    public func delete(key: String) throws {
        guard !key.isEmpty else { throw KeychainError.invalidInput }
        let service = keychainService(for: key)
        try delete(for: service.key, in: service.service)
    }

    /// Check if a key exists for a provider
    public func exists(key: String) -> Bool {
        do {
            _ = try get(key: key)
            return true
        } catch {
            return false
        }
    }

    /// Get all stored provider keys (returns provider names only, not values)
    public func storedProviders() -> [Provider] {
        Provider.allCases.filter { exists(key: $0.rawValue) }
    }

    // MARK: - Private Helpers

    private func keychainService(for key: String) -> (key: String, service: String) {
        let service = "com.icodexbar.keychain.\(key)"
        return (key: key, service: service)
    }

    // MARK: - Core Keychain Operations

    private func save(_ value: String, for key: String, in service: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }

        // Try to delete existing item first
        try? delete(for: key, in: service)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicate
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func retrieve(for key: String, in service: String) throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.encodingError
        }

        return string
    }

    private func delete(for key: String, in service: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
