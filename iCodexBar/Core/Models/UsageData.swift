import Foundation

struct UsageData: Codable, Equatable {
    let provider: Provider
    let totalTokens: Int
    let costUSD: Double
    let periodStart: Date
    let periodEnd: Date
    let fetchedAt: Date

    var formattedCost: String {
        CurrencyFormatter.format(costUSD)
    }

    var formattedTokens: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalTokens)) ?? "\(totalTokens)"
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: periodEnd).day ?? 0
    }

    var isExpired: Bool {
        Date() > periodEnd
    }
}

extension UsageData {
    static let placeholder = UsageData(
        provider: .openAI,
        totalTokens: 1_234_567,
        costUSD: 4.32,
        periodStart: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
        periodEnd: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
        fetchedAt: Date()
    )

    static func placeholder(for provider: Provider) -> UsageData {
        UsageData(
            provider: provider,
            totalTokens: Int.random(in: 500_000 ... 5_000_000),
            costUSD: Double.random(in: 1.0 ... 25.0),
            periodStart: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            periodEnd: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            fetchedAt: Date()
        )
    }
}
