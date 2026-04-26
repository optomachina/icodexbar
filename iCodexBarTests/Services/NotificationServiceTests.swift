import XCTest
import UserNotifications
@testable import iCodexBarCore

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

    func testSendUsageAlert() async throws {
        #if os(macOS)
        throw XCTSkip("UNUserNotificationCenter requires an app bundle in macOS XCTest.")
        #else
        // Send test notification
        await service.sendAlert(
            provider: .openAI,
            percent: 85,
            threshold: 80
        )

        // Verify no crash - actual notification delivery is system-dependent
        XCTAssertTrue(true)
        #endif
    }
}
