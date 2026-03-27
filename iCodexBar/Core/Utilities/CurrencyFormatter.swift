import Foundation

/// Currency formatting utilities
public enum CurrencyFormatter {

    /// Format a Double as USD: 4.32 -> "$4.32", 1234.56 -> "$1,234.56"
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.currencySymbol = "$"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// Format a value as USD string
    public static func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
    }

    /// Format with thousands separator
    public static func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        } else {
            return format(value)
        }
    }
}
