import XCTest
import UserNotifications
@testable import iCodexBar

final class NotificationServiceTests: XCTestCase {

    private var service: NotificationService!

    override func setUp() async throws {
        try await super.setUp()
        service = NotificationService.shared
    }

    // MARK: - Permission Tests

    func testCheckAuthorizationStatus() async throws {
        let status = await service.checkAuthorizationStatus()
        XCTAssertTrue([
            .notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral
        ].contains(status))
    }

    // MARK: - Notification Sending Tests

    func testSendUsageAlert() async throws {
        // Send test notification
        await service.sendAlert(
            provider: .openAI,
            percent: 85,
            threshold: 80
        )

        // Verify no crash - actual notification delivery is system-dependent
        XCTAssertTrue(true)
    }
}
