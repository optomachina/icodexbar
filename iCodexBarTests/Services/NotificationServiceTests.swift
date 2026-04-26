@testable import iCodexBarCore
import UserNotifications
import XCTest

final class NotificationServiceTests: XCTestCase {
    private var service: NotificationService!

    override func setUp() async throws {
        try await super.setUp()
        service = NotificationService.shared
    }

    // MARK: - Permission Tests

    func testCheckAuthorizationStatus() async throws {
        #if os(macOS)
            throw XCTSkip("UNUserNotificationCenter requires an app bundle in macOS XCTest.")
        #else
            let status = await service.checkAuthorizationStatus()
            var expectedStatuses: [UNAuthorizationStatus] = [
                .notDetermined,
                .denied,
                .authorized,
                .provisional
            ]
            #if os(iOS)
                expectedStatuses.append(.ephemeral)
            #endif
            XCTAssertTrue(expectedStatuses.contains(status))
        #endif
    }

    // MARK: - Notification Sending Tests

    /// Smoke test: `sendAlert` must not throw or crash on iOS even when no
    /// authorization has been granted (it should fail silently, by design).
    /// Doesn't validate the constructed `UNNotificationRequest` — that needs
    /// dependency injection of a `UNUserNotificationCenter`-like spy, which
    /// `NotificationService` doesn't currently support.
    func testSendUsageAlertDoesNotThrow() async throws {
        #if os(macOS)
            throw XCTSkip("UNUserNotificationCenter requires an app bundle in macOS XCTest.")
        #else
            await service.sendAlert(
                provider: .openAI,
                percent: 85,
                threshold: 80
            )
        #endif
    }
}
