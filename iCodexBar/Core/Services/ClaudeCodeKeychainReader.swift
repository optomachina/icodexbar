import Foundation
import Security

// MARK: - Credentials

public struct ClaudeCodeCredentials: Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date?
    public let subscriptionType: String?
    public let rateLimitTier: String?

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil,
        subscriptionType: String? = nil,
        rateLimitTier: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.subscriptionType = subscriptionType
        self.rateLimitTier = rateLimitTier
    }

    /// Resolve to a ClaudeCodePlan; falls back to `.max20x` if tier is unknown.
    public var inferredPlan: ClaudeCodePlan {
        ClaudeCodePlan(rateLimitTier: rateLimitTier) ?? .max20x
    }
}

// MARK: - Errors

public enum ClaudeCodeKeychainError: Error, LocalizedError {
    case notSignedIn
    case userDenied
    case backgroundReadGated
    case keychainStatus(OSStatus)
    case malformed(String)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Claude Code: not signed in. Open Claude Code and sign in."
        case .userDenied:
            return "Claude Code: keychain access denied. Click Refresh to retry."
        case .backgroundReadGated:
            return "Claude Code: keychain access denied recently. Click Refresh to retry."
        case let .keychainStatus(status):
            return "Claude Code keychain error: \(status)"
        case let .malformed(detail):
            return "Claude Code credentials malformed: \(detail)"
        }
    }
}

// MARK: - Reader

public enum ClaudeCodeKeychainReader {
    /// The Keychain service name Claude Code writes its credentials under.
    public static let serviceName = "Claude Code-credentials"

    /// Reads and parses the Claude Code credentials blob from the macOS Keychain.
    ///
    /// `interaction` controls whether a previously denied background read is allowed
    /// to retry. Background reads in the cooldown window throw `.backgroundReadGated`
    /// silently; user-initiated reads bypass the gate and clear the cooldown on success.
    public static func read(
        interaction: ProviderInteraction = .background,
        serviceName: String = serviceName
    ) throws -> ClaudeCodeCredentials {
        if interaction == .background, !ClaudeCodeKeychainAccessGate.shouldAllowPrompt() {
            throw ClaudeCodeKeychainError.backgroundReadGated
        }
        if interaction == .userInitiated {
            ClaudeCodeKeychainAccessGate.clearDenied()
        }
        let data = try readRawData(serviceName: serviceName)
        let creds = try parse(data: data)
        // Successful read implicitly clears any stale denial state.
        ClaudeCodeKeychainAccessGate.clearDenied()
        return creds
    }

    /// Pure parse of the raw JSON blob. Safe to unit-test.
    public static func parse(data: Data) throws -> ClaudeCodeCredentials {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeCodeKeychainError.malformed("Root is not a JSON object")
        }
        guard let oauth = root["claudeAiOauth"] as? [String: Any] else {
            throw ClaudeCodeKeychainError.malformed("Missing `claudeAiOauth` object")
        }
        guard let accessToken = oauth["accessToken"] as? String, !accessToken.isEmpty else {
            throw ClaudeCodeKeychainError.malformed("Missing `accessToken`")
        }

        let expiresAt: Date?
        if let ms = oauth["expiresAt"] as? Double {
            expiresAt = Date(timeIntervalSince1970: ms / 1000)
        } else if let ms = oauth["expiresAt"] as? Int {
            expiresAt = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        } else {
            expiresAt = nil
        }

        return ClaudeCodeCredentials(
            accessToken: accessToken,
            refreshToken: oauth["refreshToken"] as? String,
            expiresAt: expiresAt,
            subscriptionType: oauth["subscriptionType"] as? String,
            rateLimitTier: oauth["rateLimitTier"] as? String
        )
    }

    // MARK: - Private

    private static func readRawData(serviceName: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw ClaudeCodeKeychainError.malformed("Keychain returned non-data result")
            }
            return data
        case errSecItemNotFound:
            throw ClaudeCodeKeychainError.notSignedIn
        case errSecUserCanceled, errSecAuthFailed, errSecNoAccessForItem:
            ClaudeCodeKeychainAccessGate.recordDenied()
            throw ClaudeCodeKeychainError.userDenied
        default:
            throw ClaudeCodeKeychainError.keychainStatus(status)
        }
    }
}

// MARK: - ClaudeCodePlan tier mapping

extension ClaudeCodePlan {
    /// Map Anthropic's `rateLimitTier` identifier to a plan enum.
    /// Examples seen in the wild:
    ///   - `default_claude_pro`
    ///   - `default_claude_max_5x`
    ///   - `default_claude_max_20x`
    public init?(rateLimitTier: String?) {
        guard let tier = rateLimitTier?.lowercased() else { return nil }
        if tier.contains("max_20x") || tier.contains("max20x") {
            self = .max20x
        } else if tier.contains("max_5x") || tier.contains("max5x") {
            self = .max5x
        } else if tier.contains("pro") {
            self = .pro
        } else {
            return nil
        }
    }
}
