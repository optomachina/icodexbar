import Foundation
import SwiftUI

@Observable
public final class DashboardViewModel {
    public var snapshots: [Provider: ProviderUsageSnapshot?] = [:]
    public var errors: [Provider: String?] = [:]
    public var isLoading: Bool = false
    public var lastFetchedAt: Date?
    public var hasAnyConfiguredKey: Bool = false

    private let store = UsageStore.shared

    public init() {
        snapshots = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.snapshots[$0]) })
        errors = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.errors[$0]) })
        isLoading = store.isLoading
        lastFetchedAt = store.lastFetchedAt
    }

    public func refresh() async {
        isLoading = true
        await store.fetchAll()
        await syncFromStore()
    }

    public func snapshot(for provider: Provider) -> ProviderUsageSnapshot? {
        snapshots[provider] ?? nil
    }

    public func error(for provider: Provider) -> String? {
        errors[provider] ?? nil
    }

    private func syncFromStore() async {
        isLoading = store.isLoading
        snapshots = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.snapshots[$0]) })
        errors = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.errors[$0]) })
        lastFetchedAt = store.lastFetchedAt
        hasAnyConfiguredKey = await Provider.allCases.asyncContains { provider in
            await store.isConfigured(provider)
        }
    }
}

private extension Array {
    func asyncContains(_ predicate: (Element) async -> Bool) async -> Bool {
        for element in self {
            if await predicate(element) {
                return true
            }
        }
        return false
    }
}
