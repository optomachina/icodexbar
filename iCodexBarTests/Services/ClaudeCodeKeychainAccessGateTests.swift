@testable import iCodexBarCore
import XCTest

final class ClaudeCodeKeychainAccessGateTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "ClaudeCodeKeychainAccessGateTests-\(UUID().uuidString)"

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: suiteName)
        XCTAssertNotNil(defaults)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testAllowsPromptByDefault() {
        XCTAssertTrue(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(defaults: defaults))
    }

    func testRecordedDenialBlocksImmediately() {
        let now = Date()
        ClaudeCodeKeychainAccessGate.recordDenied(now: now, defaults: defaults)
        XCTAssertFalse(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(now: now, defaults: defaults))
    }

    func testCooldownExpiresAfterSixHours() {
        let now = Date()
        ClaudeCodeKeychainAccessGate.recordDenied(now: now, defaults: defaults)
        // Just before cooldown ends — still blocked.
        let almostExpired = now.addingTimeInterval(ClaudeCodeKeychainAccessGate.cooldownInterval - 60)
        XCTAssertFalse(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(now: almostExpired, defaults: defaults))
        // Just after cooldown ends — allowed again.
        let expired = now.addingTimeInterval(ClaudeCodeKeychainAccessGate.cooldownInterval + 60)
        XCTAssertTrue(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(now: expired, defaults: defaults))
    }

    func testClearDeniedAllowsImmediately() {
        let now = Date()
        ClaudeCodeKeychainAccessGate.recordDenied(now: now, defaults: defaults)
        XCTAssertFalse(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(now: now, defaults: defaults))

        ClaudeCodeKeychainAccessGate.clearDenied(defaults: defaults)
        XCTAssertTrue(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(now: now, defaults: defaults))
    }

    func testExpiredCooldownIsAutoCleared() {
        let now = Date()
        ClaudeCodeKeychainAccessGate.recordDenied(now: now, defaults: defaults)
        let expired = now.addingTimeInterval(ClaudeCodeKeychainAccessGate.cooldownInterval + 60)
        // First call observes expiration and clears it.
        XCTAssertTrue(ClaudeCodeKeychainAccessGate.shouldAllowPrompt(now: expired, defaults: defaults))
        // Persisted state should be gone.
        XCTAssertNil(defaults.object(forKey: "claudeCodeKeychainDeniedUntil"))
    }
}
