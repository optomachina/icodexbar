import Foundation

/// Number and token formatting utilities
public enum UsageFormatter {

    /// Format token count as compact string: 1234567 -> "1.23M", 456789 -> "457K"
    public static func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.2fM", Double(tokens) / 1_000_000).replacingOccurrences(of: ".00", with: "")
        } else if tokens >= 1_000 {
            return String(format: "%.0fK", Double(tokens) / 1_000)
        } else {
            return NumberFormatter.localizedString(from: NSNumber(value: tokens), number: .decimal)
        }
    }

    /// Format USD cost: 4.32 -> "$4.32", 1234.56 -> "$1,234.56"
    public static func formatUSD(_ dollars: Double) -> String {
        CurrencyFormatter.format(dollars)
    }

    /// Format percentage: 42.5 -> "43%"
    public static func formatPercent(_ percent: Double) -> String {
        "\(Int(percent.rounded()))%"
    }

    /// Format relative date: "2m ago", "yesterday", "3d ago"
    public static func formatRelativeDate(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else if seconds < 172800 {
            return "yesterday"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }

    /// Days remaining in a period ending at the given date
    public static func daysRemaining(in periodEnd: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: periodEnd)
        ).day ?? 0
    }

    /// Format days remaining as string
    public static func formatDaysRemaining(_ days: Int) -> String {
        if days <= 0 {
            return "ended"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }

    /// Format tokens + cost on a single line: "1.23M tokens · $4.32"
    public static func formatTokensAndCost(tokens: Int?, cost: Double?) -> String {
        let tokenStr = tokens.map { formatTokens($0) } ?? "—"
        let costStr = cost.map { formatUSD($0) } ?? "—"
        return "\(tokenStr) tokens · \(costStr)"
    }
}
