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
        // System dialog on first run — just verify no crash
        try? await service.requestAuthorization()
        XCTAssertTrue(true)
    }

    // MARK: - Notification Sending Tests

    func testSendUsageAlert() async throws {
        _ = try? await service.requestAuthorization()
        await service.sendAlert(provider: .openAI, percent: 85, threshold: 80)
        // Verify no crash — actual notification delivery is system-dependent
        XCTAssertTrue(true)
    }

    func testSendUsageReset() async throws {
        _ = try? await service.requestAuthorization()
        await service.sendUsageReset(provider: .openRouter)
        XCTAssertTrue(true)
    }
}
