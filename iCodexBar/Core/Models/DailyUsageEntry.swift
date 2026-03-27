import Foundation

/// A single day's usage entry for charts and history
public struct DailyUsageEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    /// Date string in yyyy-MM-dd format
    public let date: String
    public let totalTokens: Int?
    public let costUSD: Double?
    public let inputTokens: Int?
    public let outputTokens: Int?

    public init(
        date: String,
        totalTokens: Int? = nil,
        costUSD: Double? = nil,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil
    ) {
        self.id = date
        self.date = date
        self.totalTokens = totalTokens
        self.costUSD = costUSD
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try container.decode(String.self, forKey: .date)
        self.id = self.date
        self.totalTokens = try container.decodeIfPresent(Int.self, forKey: .totalTokens)
        self.costUSD = try container.decodeIfPresent(Double.self, forKey: .costUSD)
        self.inputTokens = try container.decodeIfPresent(Int.self, forKey: .inputTokens)
        self.outputTokens = try container.decodeIfPresent(Int.self, forKey: .outputTokens)
    }

    private enum CodingKeys: String, CodingKey {
        case date, totalTokens, costUSD, inputTokens, outputTokens
    }
}
