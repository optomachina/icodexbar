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
        if UserDefaults.standard.bool(forKey: "isDemoMode") { return true }
        return Provider.allCases.contains { store.isConfigured($0) }
    }

    public func refresh() async {
        guard !UserDefaults.standard.bool(forKey: "isDemoMode") else {
            loadDemoData()
            return
        }
        isLoading = true
        await store.fetchAll()
        isLoading = store.isLoading
        snapshots = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.snapshots[$0]) })
        errors = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0, store.errors[$0]) })
        lastFetchedAt = store.lastFetchedAt
    }

    private func loadDemoData() {
        let now = Date()
        snapshots[.openAI] = ProviderUsageSnapshot(
            provider: .openAI,
            primary: RateWindow(usedPercent: 68, windowMinutes: nil, resetsAt: nil, resetDescription: "in 14 days"),
            secondary: nil,
            totalTokens: 1_200_000,
            totalCostUSD: 12.40,
            balance: nil,
            dailyUsage: [],
            updatedAt: now
        )
        snapshots[.anthropic] = ProviderUsageSnapshot(
            provider: .anthropic,
            primary: RateWindow(usedPercent: 0, windowMinutes: nil, resetsAt: nil, resetDescription: "Rate limit tier: build"),
            secondary: nil,
            totalTokens: 47_000,
            totalCostUSD: 0.0,
            balance: nil,
            dailyUsage: [],
            updatedAt: now
        )
        snapshots[.openRouter] = ProviderUsageSnapshot(
            provider: .openRouter,
            primary: RateWindow(usedPercent: 38, windowMinutes: nil, resetsAt: nil, resetDescription: "Credit: $6.20"),
            secondary: nil,
            totalTokens: nil,
            totalCostUSD: 3.80,
            balance: 6.20,
            dailyUsage: [],
            updatedAt: now
        )
        lastFetchedAt = now
        isLoading = false
    }

    public func snapshot(for provider: Provider) -> ProviderUsageSnapshot? {
        snapshots[provider] ?? nil
    }

    public func error(for provider: Provider) -> String? {
        errors[provider]
    }
}
