import Foundation

/// Whether a request originated from a user action (click, Refresh) or a
/// background timer. Background reads should not surprise-prompt the user
/// after they've previously denied Keychain access.
public enum ProviderInteraction: Sendable {
    case background
    case userInitiated
}

/// Persists a cooldown after the user denies Keychain access for the
/// `Claude Code-credentials` item. While the cooldown is active, background
/// refresh paths skip the read and return `.notSignedIn` silently. User-initiated
/// reads bypass the gate and clear the cooldown on success.
///
/// Mirrors steipete/CodexBar `ClaudeOAuthKeychainAccessGate` semantics with a
/// 6-hour cooldown.
public enum ClaudeCodeKeychainAccessGate {
    static let cooldownInterval: TimeInterval = 6 * 60 * 60
    /// UserDefaults key the gate persists denial state under. Exposed for tests so
    /// renames here can't silently leave assertions referencing a stale literal.
    public static let deniedUntilKey = "claudeCodeKeychainDeniedUntil"

    /// True if a background read is allowed to attempt the Keychain (and
    /// potentially trigger a system prompt). False during the cooldown window.
    public static func shouldAllowPrompt(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard let raw = defaults.object(forKey: deniedUntilKey) as? Double else {
            return true
        }
        let deniedUntil = Date(timeIntervalSince1970: raw)
        if deniedUntil > now {
            return false
        }
        defaults.removeObject(forKey: deniedUntilKey)
        return true
    }

    /// Records a denial; subsequent background reads will be skipped until the
    /// cooldown expires.
    public static func recordDenied(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let deniedUntil = now.addingTimeInterval(cooldownInterval)
        defaults.set(deniedUntil.timeIntervalSince1970, forKey: deniedUntilKey)
    }

    /// Clears the cooldown — called on a successful read or on user-initiated retry.
    public static func clearDenied(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: deniedUntilKey)
    }
}
