import Foundation

// MARK: - Record types

/// A single event line from `~/.claude/projects/<project>/<session>.jsonl`.
/// We only need a small slice of the schema; tolerant decoder ignores extras.
public struct ClaudeCodeRecord: Decodable, Sendable {
    public let type: String
    public let timestamp: Date?
    public let sessionId: String?
    public let message: Message?

    public struct Message: Decodable, Sendable {
        public let model: String?
        public let usage: Usage?

        enum CodingKeys: String, CodingKey {
            case model, usage
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            model = try? container.decodeIfPresent(String.self, forKey: .model)
            usage = try? container.decodeIfPresent(Usage.self, forKey: .usage)
        }
    }

    public struct Usage: Decodable, Sendable {
        public let inputTokens: Int
        public let cacheCreationInputTokens: Int
        public let cacheReadInputTokens: Int
        public let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case outputTokens = "output_tokens"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            inputTokens = (try? container.decode(Int.self, forKey: .inputTokens)) ?? 0
            cacheCreationInputTokens = (try? container.decode(Int.self, forKey: .cacheCreationInputTokens)) ?? 0
            cacheReadInputTokens = (try? container.decode(Int.self, forKey: .cacheReadInputTokens)) ?? 0
            outputTokens = (try? container.decode(Int.self, forKey: .outputTokens)) ?? 0
        }

        /// Cache-creation is billed at 25% of input rate; cache-read at 10%.
        /// This is the unit we use to compare against quota (Anthropic counts cache the same way).
        public var weightedBillableTokens: Int {
            inputTokens
                + Int(Double(cacheCreationInputTokens) * 0.25)
                + Int(Double(cacheReadInputTokens) * 0.10)
                + outputTokens
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, timestamp, sessionId, message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? container.decode(String.self, forKey: .type)) ?? ""
        sessionId = try? container.decodeIfPresent(String.self, forKey: .sessionId)
        message = try? container.decodeIfPresent(Message.self, forKey: .message)
        if let raw = try? container.decodeIfPresent(String.self, forKey: .timestamp) {
            timestamp = Self.iso8601.date(from: raw)
        } else {
            timestamp = nil
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

// MARK: - Plan tier

/// Quota numbers for the Claude Code subscription tiers.
/// Defaults to `.max20x` — generous tier; underestimates % for smaller plans.
/// Surface as a user-configurable setting in M2.
public enum ClaudeCodePlan: String, Sendable, CaseIterable {
    case pro
    case max5x
    case max20x

    /// 5h rolling-window quota in weighted billable tokens.
    public var sessionTokenQuota: Int {
        switch self {
        case .pro: 250_000
        case .max5x: 1_250_000
        case .max20x: 5_000_000
        }
    }

    /// 7-day rolling weekly quota in weighted billable tokens.
    public var weeklyTokenQuota: Int {
        switch self {
        case .pro: 5_000_000
        case .max5x: 25_000_000
        case .max20x: 100_000_000
        }
    }
}

// MARK: - Pricing

/// Per-million-token USD rates. Update when Anthropic moves prices.
/// Cache-creation/read multipliers are applied to the input rate at billing time.
public enum ClaudeCodePricing {
    public struct Rate: Sendable {
        public let inputPerMTok: Double
        public let outputPerMTok: Double
    }

    public static func rate(for model: String?) -> Rate {
        guard let model = model?.lowercased() else { return .opus }
        if model.contains("opus") { return .opus }
        if model.contains("sonnet") { return .sonnet }
        if model.contains("haiku") { return .haiku }
        return .opus
    }

    public static func costUSD(for usage: ClaudeCodeRecord.Usage, model: String?) -> Double {
        let rate = rate(for: model)
        let inputCost = (Double(usage.inputTokens) / 1_000_000) * rate.inputPerMTok
        let cacheCreationCost =
            (Double(usage.cacheCreationInputTokens) / 1_000_000) * rate.inputPerMTok * 1.25
        let cacheReadCost =
            (Double(usage.cacheReadInputTokens) / 1_000_000) * rate.inputPerMTok * 0.10
        let outputCost = (Double(usage.outputTokens) / 1_000_000) * rate.outputPerMTok
        return inputCost + cacheCreationCost + cacheReadCost + outputCost
    }
}

public extension ClaudeCodePricing.Rate {
    static let opus = Self(inputPerMTok: 15.0, outputPerMTok: 75.0)
    static let sonnet = Self(inputPerMTok: 3.0, outputPerMTok: 15.0)
    static let haiku = Self(inputPerMTok: 0.80, outputPerMTok: 4.0)
}
