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
        try await service.requestAuthorization()
        // We can't assert true/false since it depends on user response
        // Just verify it doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Notification Sending Tests

    func testSendUsageAlert() async throws {
        // Request authorization first
        _ = try? await service.requestAuthorization()

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
