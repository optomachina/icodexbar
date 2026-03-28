import Foundation

// MARK: - Provider API Errors

public enum ProviderAPIError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case apiError(Int, String)
    case parseError(String)
    case rateLimited
    case notConfigured

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid API key"
        case let .networkError(msg): return "Network error: \(msg)"
        case let .apiError(code, msg): return "API error \(code): \(msg)"
        case let .parseError(msg): return "Parse error: \(msg)"
        case .rateLimited: return "Rate limited. Try again later."
        case .notConfigured: return "API key not configured"
        }
    }
}

// MARK: - Usage Fetching Protocol

public protocol UsageAPIFetching: Sendable {
    func fetchUsage(apiKey: String) async throws -> ProviderUsageSnapshot
}

// MARK: - OpenAI Usage API

public struct OpenAIUsageAPI: UsageAPIFetching {

    public static let shared = OpenAIUsageAPI()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchUsage(apiKey: String) async throws -> ProviderUsageSnapshot {
        guard !apiKey.isEmpty else { throw ProviderAPIError.notConfigured }

        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let startStr = dateFormatter.string(from: startOfMonth)
        let endStr = dateFormatter.string(from: now)

        let url = URL(string: "https://api.openai.com/v1/billing/usage?start_date=\(startStr)&end_date=\(endStr)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderAPIError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw ProviderAPIError.invalidCredentials
        case 429:
            throw ProviderAPIError.rateLimited
        default:
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw ProviderAPIError.apiError(httpResponse.statusCode, body.prefix(200).description)
        }

        do {
            let report = try JSONDecoder().decode(OpenAIDailyReport.self, from: data)
            return parseReport(report, updatedAt: now)
        } catch let error as DecodingError {
            throw ProviderAPIError.parseError("Usage response: \(error.localizedDescription)")
        } catch {
            throw ProviderAPIError.parseError(error.localizedDescription)
        }
    }

    private func parseReport(_ report: OpenAIDailyReport, updatedAt: Date) -> ProviderUsageSnapshot {
        let totalTokens = report.data.reduce(0) { $0 + ($1.totalTokens ?? 0) }
        let totalCost = report.data.reduce(0.0) { $0 + ($1.costUSD ?? 0) }

        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysPassed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 1
        let dailyAvgCost = daysPassed > 0 ? totalCost / Double(daysPassed) : 0
        let projectedCost = dailyAvgCost * Double(daysInMonth)

        let primaryPercent = projectedCost > 0 ? min(200, (totalCost / projectedCost) * 100) : 0
        let remainingDays = daysInMonth - daysPassed

        let primary = RateWindow(
            usedPercent: primaryPercent,
            windowMinutes: nil,
            resetsAt: calendar.date(byAdding: .month, value: 1, to: startOfMonth),
            resetDescription: remainingDays == 1 ? "tomorrow" : "in \(remainingDays) days"
        )

        let dailyEntries = report.data.map { entry in
            DailyUsageEntry(
                date: entry.date,
                totalTokens: entry.totalTokens,
                costUSD: entry.costUSD,
                inputTokens: entry.inputTokens,
                outputTokens: entry.outputTokens
            )
        }

        return ProviderUsageSnapshot(
            provider: .openAI,
            primary: primary,
            secondary: nil,
            totalTokens: totalTokens,
            totalCostUSD: totalCost,
            balance: nil,
            dailyUsage: dailyEntries,
            updatedAt: updatedAt
        )
    }
}

// MARK: - OpenAI API Response Models

private struct OpenAIDailyReport: Decodable {
    let data: [OpenAIDailyEntry]

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct OpenAIDailyEntry: Decodable {
    let date: String
    let totalTokens: Int?
    let costUSD: Double?
    let inputTokens: Int?
    let outputTokens: Int?

    private enum CodingKeys: String, CodingKey {
        case date
        case totalTokens = "n_tokens_total"
        case costUSD = "cost"
        case inputTokens = "n_context_tokens_total"
        case outputTokens = "n_generated_tokens_total"
    }
}

// MARK: - OpenRouter Usage API

public struct OpenRouterUsageAPI: UsageAPIFetching {

    public static let shared = OpenRouterUsageAPI()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchUsage(apiKey: String) async throws -> ProviderUsageSnapshot {
        guard !apiKey.isEmpty else { throw ProviderAPIError.notConfigured }

        // Fetch credits
        let creditsURL = URL(string: "https://openrouter.ai/api/v1/credits")!
        var creditsRequest = URLRequest(url: creditsURL)
        creditsRequest.httpMethod = "GET"
        creditsRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        creditsRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        creditsRequest.timeoutInterval = 20

        let (creditsData, creditsResponse) = try await session.data(for: creditsRequest)

        guard let httpResponse = creditsResponse as? HTTPURLResponse else {
            throw ProviderAPIError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw ProviderAPIError.invalidCredentials
        case 429:
            throw ProviderAPIError.rateLimited
        default:
            throw ProviderAPIError.apiError(httpResponse.statusCode, "Credits fetch failed")
        }

        let credits = try JSONDecoder().decode(OpenRouterCredits.self, from: creditsData)

        // Race fetch key info with 1s timeout
        let keyInfo = await fetchKeyInfo(apiKey: apiKey)

        let now = Date()
        let balance = credits.data.balance
        let totalCredits = credits.data.totalCredits
        let totalUsage = credits.data.totalUsage
        let usedPercent = totalCredits > 0 ? (totalUsage / totalCredits) * 100 : 0

        let primary = RateWindow(
            usedPercent: min(100, usedPercent),
            windowMinutes: nil,
            resetsAt: nil,
            resetDescription: balance > 0 ? "Credit: \(CurrencyFormatter.format(balance))" : nil
        )

        var secondary: RateWindow? = nil
        if let keyLimit = keyInfo?.limit, let keyUsage = keyInfo?.usage, keyLimit > 0 {
            let keyPercent = (keyUsage / keyLimit) * 100
            secondary = RateWindow(
                usedPercent: min(100, keyPercent),
                windowMinutes: nil,
                resetsAt: nil,
                resetDescription: "Key limit"
            )
        }

        return ProviderUsageSnapshot(
            provider: .openRouter,
            primary: primary,
            secondary: secondary,
            totalTokens: nil,
            totalCostUSD: totalUsage,
            balance: balance,
            dailyUsage: [],
            updatedAt: now
        )
    }

    private func fetchKeyInfo(apiKey: String) async -> OpenRouterKeyInfo? {
        await withTaskGroup(of: OpenRouterKeyInfo?.self) { group in
            group.addTask {
                await self.fetchKeyInfoRequest(apiKey: apiKey)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                return nil
            }
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }

    private func fetchKeyInfoRequest(apiKey: String) async -> OpenRouterKeyInfo? {
        let keyURL = URL(string: "https://openrouter.ai/api/v1/key")!
        var request = URLRequest(url: keyURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 2

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return try? JSONDecoder().decode(OpenRouterKeyInfo.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - OpenRouter API Response Models

private struct OpenRouterCredits: Decodable {
    let data: OpenRouterCreditsData
}

private struct OpenRouterCreditsData: Decodable {
    let totalCredits: Double
    let totalUsage: Double
    let balance: Double

    private enum CodingKeys: String, CodingKey {
        case totalCredits = "total_credits"
        case totalUsage = "total_usage"
        case balance
    }
}

private struct OpenRouterKeyInfo: Decodable {
    let limit: Double?
    let usage: Double?
    let rateLimit: OpenRouterRateLimit?

    private enum CodingKeys: String, CodingKey {
        case limit, usage
        case rateLimit = "rate_limit"
    }
}

private struct OpenRouterRateLimit: Codable {
    let requests: Int
    let interval: String
}

// MARK: - Anthropic Usage API

public struct AnthropicUsageAPI: UsageAPIFetching {

    public static let shared = AnthropicUsageAPI()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Anthropic does not have a public billing API. This implementation makes
    /// a minimal /v1/messages call and extracts token usage from response headers.
    /// Running totals are persisted to UserDefaults for the current billing period.
    public func fetchUsage(apiKey: String) async throws -> ProviderUsageSnapshot {
        guard !apiKey.isEmpty else { throw ProviderAPIError.notConfigured }

        // Make a minimal API call to get usage from headers
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("anthropic-version: 2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let body: [String: Any] = [
            "model": "claude-haiku-4-20250514",
            "max_tokens": 10,
            "messages": [["role": "user", "content": "ping"]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderAPIError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200, 201:
            break
        case 401, 403:
            throw ProviderAPIError.invalidCredentials
        case 429:
            throw ProviderAPIError.rateLimited
        default:
            throw ProviderAPIError.apiError(httpResponse.statusCode, "Anthropic fetch failed")
        }

        // Extract usage from response headers (anthropic-usage contains token counts)
        let usageHeader = httpResponse.value(forHTTPHeaderField: "anthropic-usage")
        let billingPeriod = currentBillingPeriod()

        var inputTokens = 0
        var outputTokens = 0

        if let usageHeader, let data = usageHeader.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            inputTokens = json["input_tokens"] as? Int ?? 0
            outputTokens = json["output_tokens"] as? Int ?? 0
        }

        let totalTokens = inputTokens + outputTokens

        // Load persisted cumulative totals from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.icodexbar.shared") ?? .standard
        let key = "anthropic_usage_\(billingPeriod)"
        var cumulative = CumulativeAnthropicUsage(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            apiCalls: 1
        )

        if let saved = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(CumulativeAnthropicUsage.self, from: saved) {
            // If it's a new hour, we've made a fresh API call so add to cumulative
            cumulative = CumulativeAnthropicUsage(
                inputTokens: decoded.inputTokens + inputTokens,
                outputTokens: decoded.outputTokens + outputTokens,
                apiCalls: decoded.apiCalls + 1
            )
        }

        if let encoded = try? JSONEncoder().encode(cumulative) {
            defaults.set(encoded, forKey: key)
        }

        // Estimate cost using Anthropic's published pricing
        // Haiku: $0.25/M input, $1.25/M output (approximate)
        let estimatedCost = (Double(cumulative.inputTokens) * 0.25 / 1_000_000)
            + (Double(cumulative.outputTokens) * 1.25 / 1_000_000)

        let now = Date()
        let calendar = Calendar.current
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysPassed = calendar.dateComponents([.day], from: periodStart, to: now).day ?? 1
        let dailyAvgCost = daysPassed > 0 ? estimatedCost / Double(daysPassed) : 0
        let projectedCost = dailyAvgCost * Double(daysInMonth)
        let costPercent = projectedCost > 0 ? min(200, (estimatedCost / projectedCost) * 100) : 0

        let primary = RateWindow(
            usedPercent: costPercent,
            windowMinutes: nil,
            resetsAt: calendar.date(byAdding: .month, value: 1, to: periodStart),
            resetDescription: "Projected — no billing API available"
        )

        return ProviderUsageSnapshot(
            provider: .anthropic,
            primary: primary,
            secondary: nil,
            totalTokens: cumulative.inputTokens + cumulative.outputTokens,
            totalCostUSD: estimatedCost,
            balance: nil,
            dailyUsage: [],
            updatedAt: now
        )
    }

    private func currentBillingPeriod() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}

private struct CumulativeAnthropicUsage: Codable {
    var inputTokens: Int
    var outputTokens: Int
    var apiCalls: Int
}
