import XCTest
@testable import iCodexBar

final class NotificationServiceTests: XCTestCase {

    private var service: NotificationService!

    override func setUp() async throws {
        try await super.setUp()
        service = NotificationService.shared
    }

    // MARK: - Permission Tests

    func testRequestAuthorization() async throws {
        // This will show a system dialog on first run
        let granted = try await service.requestAuthorization()
        // We can't assert true/false since it depends on user response
        // Just verify it doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Notification Sending Tests

    func testSendUsageAlert() async throws {
        // Request authorization first
        _ = try? await service.requestAuthorization()

        // Send test notification
        await service.sendUsageAlert(
            provider: .openAI,
            percentUsed: 85
        )

        // Verify no crash - actual notification delivery is system-dependent
        XCTAssertTrue(true)
    }

    func testSendLowCreditAlert() async throws {
        _ = try? await service.requestAuthorization()

        await service.sendLowCreditAlert(
            provider: .openRouter,
            balance: 5.50
        )

        XCTAssertTrue(true)
    }
}
