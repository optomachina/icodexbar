import Foundation
import SwiftUI

@Observable
public final class DashboardViewModel {

    public var snapshots: [Provider: ProviderUsageSnapshot?] = [:]
    public var errors: [Provider: String?] = [:]
    public var isLoading: Bool = false
    public var lastFetchedAt: Date?

    private let store = UsageStore.shared

    public init() {
        snapshots = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.snapshots[$0]) })
        errors = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.errors[$0]) })
        isLoading = store.isLoading
        lastFetchedAt = store.lastFetchedAt
    }

    public var hasAnyConfiguredKey: Bool {
        Provider.allCases.contains { store.isConfigured($0) }
    }

    public func refresh() async {
        isLoading = true
        await store.fetchAll()
        isLoading = store.isLoading
        snapshots = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.snapshots[$0]) })
        errors = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.errors[$0]) })
        lastFetchedAt = store.lastFetchedAt
    }

    public func snapshot(for provider: Provider) -> ProviderUsageSnapshot? {
        snapshots[provider] ?? nil
    }

    public func error(for provider: Provider) -> String? {
        errors[provider]
    }
}
