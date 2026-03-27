import Foundation

// MARK: - Rate Window

/// Represents a usage limit window (e.g., monthly, weekly, session)
public struct RateWindow: Codable, Equatable, Sendable {
    /// Usage percentage remaining (0-100)
    public let usedPercent: Double
    /// Window duration in minutes (nil for monthly/billing-cycle windows)
    public let windowMinutes: Int?
    /// When the window resets (nil for monthly)
    public let resetsAt: Date?
    /// Human-readable reset description ("in 12 days", "tomorrow")
    public let resetDescription: String?

    public init(
        usedPercent: Double,
        windowMinutes: Int? = nil,
        resetsAt: Date? = nil,
        resetDescription: String? = nil
    ) {
        self.usedPercent = usedPercent
        self.windowMinutes = windowMinutes
        self.resetsAt = resetsAt
        self.resetDescription = resetDescription
    }

    /// Percent remaining (0-100), clamped to valid range
    public var remainingPercent: Double {
        max(0, min(100, 100 - usedPercent))
    }
}
