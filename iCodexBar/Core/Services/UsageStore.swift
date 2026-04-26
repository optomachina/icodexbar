import Foundation
import WidgetKit

/// Central store for all provider usage data
/// Persists to App Group UserDefaults so the widget can read it
@Observable
public final class UsageStore {

    public static let shared = UsageStore()

    public var snapshots: [Provider: ProviderUsageSnapshot] = [:]
    public var errors: [Provider: String] = [:]
    public var isLoading: Bool = false
    public var lastFetchedAt: Date?

    private let appGroupID = "group.com.icodexbar.shared"
    private let snapshotsKey = "provider_usage_snapshots"
    private let lastFetchedKey = "last_fetched_at"
    private let thresholdsKey = "alert_thresholds"
    private let lastNotifiedKey = "last_notified_percent"

    /// Track last notified percentage per provider to avoid duplicate alerts
    private var lastNotifiedPercent: [Provider: Int] = [:]

    private init() {
        loadFromAppGroup()
        loadLastNotifiedState()
    }

    // MARK: - Public API

    public func fetchAll() async {
        isLoading = true
        errors = [:]

        await withTaskGroup(of: (Provider, ProviderUsageSnapshot?).self) { group in
            for provider in Provider.allCases {
                group.addTask {
                    (provider, await self.fetchProvider(provider))
                }
            }

            for await (provider, snapshot) in group {
                if let snapshot {
                    snapshots[provider] = snapshot
                }
            }
        }

        lastFetchedAt = Date()
        isLoading = false
        saveToAppGroup()
        reloadWidgets()
        
        // Check thresholds and trigger notifications
        await checkThresholdsAndNotify()
    }

    public func fetchProvider(_ provider: Provider) async -> ProviderUsageSnapshot? {
        guard let apiKey = try? KeychainService.shared.get(key: provider.rawValue), !apiKey.isEmpty else {
            errors[provider] = "No API key configured"
            return nil
        }

        do {
            let snapshot: ProviderUsageSnapshot
            switch provider {
            case .openAI:
                snapshot = try await OpenAIUsageAPI.shared.fetchUsage(apiKey: apiKey)
            case .openRouter:
                snapshot = try await OpenRouterUsageAPI.shared.fetchUsage(apiKey: apiKey)
            case .anthropic:
                snapshot = try await AnthropicUsageAPI.shared.fetchUsage(apiKey: apiKey)
            }
            errors[provider] = nil
            return snapshot
        } catch let error as ProviderAPIError {
            errors[provider] = error.localizedDescription
            return nil
        } catch {
            errors[provider] = error.localizedDescription
            return nil
        }
    }

    public func clearError(for provider: Provider) {
        errors[provider] = nil
    }

    public func isConfigured(_ provider: Provider) -> Bool {
        do {
            let key = try KeychainService.shared.get(key: provider.rawValue)
            return !key.isEmpty
        } catch {
            return false
        }
    }

    public func configuredProviders() -> [Provider] {
        Provider.allCases.filter { isConfigured($0) }
    }

    // MARK: - App Group Persistence (for Widget)

    public func saveToAppGroup() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(snapshots) {
            defaults.set(data, forKey: snapshotsKey)
        }
        if let lastFetchedAt {
            defaults.set(lastFetchedAt, forKey: lastFetchedKey)
        }

        defaults.synchronize()
    }

    public func loadFromAppGroup() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = defaults.data(forKey: snapshotsKey),
           let decoded = try? decoder.decode([Provider: ProviderUsageSnapshot].self, from: data) {
            snapshots = decoded
        }
        lastFetchedAt = defaults.object(forKey: lastFetchedKey) as? Date
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Threshold Checking & Notifications

    private func checkThresholdsAndNotify() async {
        let thresholds = loadThresholds()
        guard !thresholds.isEmpty else { return }
        
        for threshold in thresholds where threshold.isEnabled {
            guard let snapshot = snapshots[threshold.provider],
                  let primary = snapshot.primary else { continue }
            
            let usedPercent = Int(primary.usedPercent)
            let thresholdPercent = threshold.thresholdPercent
            
            // Only notify if threshold is crossed and we haven't already notified for this level
            if usedPercent >= thresholdPercent {
                let lastNotified = lastNotifiedPercent[threshold.provider] ?? 0
                
                // Notify if we haven't already notified for this or higher percentage
                if lastNotified < thresholdPercent {
                    await NotificationService.shared.sendAlert(
                        provider: threshold.provider,
                        percent: usedPercent,
                        threshold: thresholdPercent
                    )
                    
                    // Update last notified state
                    lastNotifiedPercent[threshold.provider] = usedPercent
                    saveLastNotifiedState()
                }
            } else if usedPercent < thresholdPercent {
                // Reset notification tracking when usage drops below threshold
                // This allows re-notification if usage rises again
                if lastNotifiedPercent[threshold.provider] != nil {
                    lastNotifiedPercent[threshold.provider] = nil
                    saveLastNotifiedState()
                }
            }
        }
    }

    private func loadThresholds() -> [AlertThreshold] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return Provider.allCases.map { AlertThreshold(provider: $0) }
        }
        
        if let data = defaults.data(forKey: thresholdsKey),
           let decoded = try? JSONDecoder().decode([AlertThreshold].self, from: data) {
            return decoded
        }
        
        return Provider.allCases.map { AlertThreshold(provider: $0) }
    }

    private func loadLastNotifiedState() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        
        if let data = defaults.data(forKey: lastNotifiedKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            lastNotifiedPercent = [:]
            for (key, value) in decoded {
                if let provider = Provider(rawValue: key) {
                    lastNotifiedPercent[provider] = value
                }
            }
        }
    }

    private func saveLastNotifiedState() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        
        let dict = Dictionary(uniqueKeysWithValues: lastNotifiedPercent.map { ($0.key.rawValue, $0.value) })
        
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: lastNotifiedKey)
            defaults.synchronize()
        }
    }
}
