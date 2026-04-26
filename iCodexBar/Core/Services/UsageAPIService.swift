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
        case .invalidCredentials: "Invalid API key"
        case let .networkError(msg): "Network error: \(msg)"
        case let .apiError(code, msg): "API error \(code): \(msg)"
        case let .parseError(msg): "Parse error: \(msg)"
        case .rateLimited: "Rate limited. Try again later."
        case .notConfigured: "API key not configured"
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
        let startUnix = Int(startOfMonth.timeIntervalSince1970)
        let endUnix = Int(now.timeIntervalSince1970)

        // TODO(admin-key): /v1/organization/costs requires an sk-admin-* key with org permissions.
        // APIKeyEntryView currently accepts any sk-* prefix; users with non-admin keys will hit
        // 401 here. Tighten validation in fix/openai-admin-key-validation.
        var components = URLComponents(string: "https://api.openai.com/v1/organization/costs")!
        components.queryItems = [
            URLQueryItem(name: "start_time", value: "\(startUnix)"),
            URLQueryItem(name: "end_time", value: "\(endUnix)"),
            URLQueryItem(name: "bucket_width", value: "1d"),
        ]
        let url = components.url!

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
            let report = try JSONDecoder().decode(OpenAICostsResponse.self, from: data)
            return parseReport(report, updatedAt: now)
        } catch let error as DecodingError {
            throw ProviderAPIError.parseError("Usage response: \(error.localizedDescription)")
        } catch {
            throw ProviderAPIError.parseError(error.localizedDescription)
        }
    }

    func parseReport(_ report: OpenAICostsResponse, updatedAt: Date) -> ProviderUsageSnapshot {
        let totalCost = report.data.reduce(0.0) { bucketTotal, bucket in
            bucketTotal + bucket.results.reduce(0.0) { resultTotal, result in
                resultTotal + (result.amount?.value ?? 0)
            }
        }

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

        let dailyEntries = report.data.map { bucket in
            let cost = bucket.results.reduce(0.0) { $0 + ($1.amount?.value ?? 0) }
            let date = Date(timeIntervalSince1970: TimeInterval(bucket.startTime))
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"

            return DailyUsageEntry(
                date: formatter.string(from: date),
                totalTokens: nil,
                costUSD: cost
            )
        }

        return ProviderUsageSnapshot(
            provider: .openAI,
            primary: primary,
            secondary: nil,
            totalTokens: nil,
            totalCostUSD: totalCost,
            balance: nil,
            dailyUsage: dailyEntries,
            updatedAt: updatedAt
        )
    }
}

// MARK: - OpenAI API Response Models

struct OpenAICostsResponse: Decodable {
    let data: [Bucket]

    struct Bucket: Decodable {
        let startTime: Int
        let results: [Result]

        private enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case results
        }
    }

    struct Result: Decodable {
        let amount: Amount?
    }

    struct Amount: Decodable {
        let value: Double?
        let currency: String?
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
                await fetchKeyInfoRequest(apiKey: apiKey)
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
    /// a minimal /v1/messages call and extracts token usage from the response body.
    /// Running totals are persisted to UserDefaults for the current billing period.
    public func fetchUsage(apiKey: String) async throws -> ProviderUsageSnapshot {
        guard !apiKey.isEmpty else { throw ProviderAPIError.notConfigured }

        // Make a minimal API call to get usage from the response body.
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        // TODO: Keep model id current with Anthropic releases.
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 10,
            "messages": [["role": "user", "content": "ping"]],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

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

        let billingPeriod = currentBillingPeriod()

        let message: AnthropicMessageResponse
        do {
            message = try JSONDecoder().decode(AnthropicMessageResponse.self, from: data)
        } catch let error as DecodingError {
            throw ProviderAPIError.parseError("Anthropic response: \(error.localizedDescription)")
        } catch {
            throw ProviderAPIError.parseError(error.localizedDescription)
        }

        let inputTokens = message.usage.inputTokens
        let outputTokens = message.usage.outputTokens
        // Load persisted cumulative totals from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.icodexbar.shared") ?? .standard
        let key = "anthropic_usage_\(billingPeriod)"
        var cumulative = CumulativeAnthropicUsage(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            apiCalls: 1
        )

        if let saved = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(CumulativeAnthropicUsage.self, from: saved)
        {
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

        // Estimate cost using Anthropic's published Claude Haiku 4.5 pricing.
        let estimatedCost = (Double(cumulative.inputTokens) * 1.0 / 1_000_000)
            + (Double(cumulative.outputTokens) * 5.0 / 1_000_000)

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

struct AnthropicMessageResponse: Decodable {
    struct Usage: Decodable {
        let inputTokens: Int
        let outputTokens: Int

        private enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }

    let usage: Usage
}

private struct CumulativeAnthropicUsage: Codable {
    var inputTokens: Int
    var outputTokens: Int
    var apiCalls: Int
}
