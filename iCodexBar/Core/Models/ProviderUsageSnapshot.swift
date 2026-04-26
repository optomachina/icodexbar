import Foundation

/// Unified snapshot for any provider's current usage state
public struct ProviderUsageSnapshot: Codable, Equatable, Sendable {
    public static let placeholder = ProviderUsageSnapshot(
        provider: .openAI,
        primary: RateWindow(usedPercent: 42),
        totalTokens: 1_500_000,
        totalCostUSD: 12.34
    )

    public let provider: Provider
    /// Primary rate limit (e.g., monthly spend limit)
    public let primary: RateWindow?
    /// Secondary rate limit (e.g., weekly, session, or credit-based)
    public let secondary: RateWindow?
    /// Total tokens used in current billing period
    public let totalTokens: Int?
    /// Total cost in USD for current billing period
    public let totalCostUSD: Double?
    /// Remaining credit balance (for credit-based providers like OpenRouter)
    public let balance: Double?
    /// Daily usage breakdown for charts
    public let dailyUsage: [DailyUsageEntry]
    /// When this snapshot was fetched
    public let updatedAt: Date

    public init(
        provider: Provider,
        primary: RateWindow? = nil,
        secondary: RateWindow? = nil,
        totalTokens: Int? = nil,
        totalCostUSD: Double? = nil,
        balance: Double? = nil,
        dailyUsage: [DailyUsageEntry] = [],
        updatedAt: Date = Date()
    ) {
        self.provider = provider
        self.primary = primary
        self.secondary = secondary
        self.totalTokens = totalTokens
        self.totalCostUSD = totalCostUSD
        self.balance = balance
        self.dailyUsage = dailyUsage
        self.updatedAt = updatedAt
    }

    /// Convenience: effective remaining percent (prefers secondary if available)
    public var effectiveRemainingPercent: Double {
        secondary?.remainingPercent ?? primary?.remainingPercent ?? 100
    }

    /// Convenience: formatted cost string
    public var formattedCost: String {
        guard let cost = totalCostUSD else { return "—" }
        return CurrencyFormatter.format(cost)
    }

    /// Convenience: formatted token count
    public var formattedTokens: String {
        guard let tokens = totalTokens else { return "—" }
        return UsageFormatter.formatTokens(tokens)
    }
}

// MARK: - Coding Keys

private enum CodingKeys: String, CodingKey {
    case provider, primary, secondary, totalTokens, totalCostUSD
    case balance, dailyUsage, updatedAt
}
