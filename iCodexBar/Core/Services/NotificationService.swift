import Foundation
import UserNotifications

public actor NotificationService {

    public static let shared = NotificationService()

    private init() {}

    // TODO: Add a dedicated low-credit alert when Balance mode lands.

    // MARK: - Authorization

    public func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted {
            throw NotificationError.authorizationDenied
        }
    }

    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Alert Notifications

    public func sendAlert(provider: Provider, percent: Int, threshold: Int) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "\(provider.displayName) Usage Alert"
        content.body = "You've used \(percent)% of your \(provider.displayName) budget, exceeding your \(threshold)% threshold."
        content.sound = .default
        content.categoryIdentifier = "USAGE_ALERT"
        content.userInfo = [
            "provider": provider.rawValue,
            "percent": percent,
            "threshold": threshold
        ]

        let request = UNNotificationRequest(
            identifier: "alert-\(provider.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil  // deliver immediately
        )

        do {
            try await center.add(request)
        } catch {
            // Notifications are best-effort; fail silently
        }
    }

    public func sendUsageReset(provider: Provider) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "\(provider.displayName) Period Reset"
        content.body = "Your \(provider.displayName) usage tracking has been reset for the new billing period."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "reset-\(provider.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            // Best-effort
        }
    }

    // MARK: - Alert Evaluation

    func evaluateAlerts(snapshots: [Provider: ProviderUsageSnapshot], thresholds: [AlertThreshold]) async {
        for threshold in thresholds where threshold.isEnabled {
            guard let snapshot = snapshots[threshold.provider] else { continue }
            let usedPercent = Int(snapshot.primary?.usedPercent ?? 0)
            if usedPercent >= threshold.thresholdPercent {
                await sendAlert(provider: threshold.provider, percent: usedPercent, threshold: threshold.thresholdPercent)
            }
        }
    }
}

public enum NotificationError: LocalizedError {
    case authorizationDenied

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Notification permission denied. Enable in Settings."
        }
    }
}
