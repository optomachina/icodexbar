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

    private init() {
        loadFromAppGroup()
    }

    // MARK: - Public API

    public func fetchAll() async {
        isLoading = true
        errors = [:]

        await withTaskGroup(of: (Provider, ProviderUsageSnapshot?).self) { group in
            for provider in Provider.allCases {
                group.addTask {
                    await self.fetchProvider(provider)
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
    }

    public func fetchProvider(_ provider: Provider) async -> ProviderUsageSnapshot? {
        guard let apiKey = try? await KeychainService.shared.get(key: provider.rawValue) else {
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
}
