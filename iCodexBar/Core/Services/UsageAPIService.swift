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
            URLQueryItem(name: "bucket_width", value: "1d")
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
        case 404:
            throw ProviderAPIError.apiError(404,
                                            "OpenAI billing API unavailable — use a legacy org API key (not a project key)")
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

        var secondary: RateWindow?
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
            return result.flatMap { $0 }
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

struct OpenRouterCredits: Decodable {
    let data: OpenRouterCreditsData
}

struct OpenRouterCreditsData: Decodable {
    let totalCredits: Double
    let totalUsage: Double
    let balance: Double

    private enum CodingKeys: String, CodingKey {
        case totalCredits = "total_credits"
        case totalUsage = "total_usage"
        case balance
    }
}

struct OpenRouterKeyInfo: Decodable {
    let limit: Double?
    let usage: Double?
    let rateLimit: OpenRouterRateLimit?

    private enum CodingKeys: String, CodingKey {
        case limit, usage
        case rateLimit = "rate_limit"
    }
}

struct OpenRouterRateLimit: Codable {
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

    public func fetchUsage(apiKey: String) async throws -> ProviderUsageSnapshot {
        guard !apiKey.isEmpty else { throw ProviderAPIError.notConfigured }

        let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderAPIError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw ProviderAPIError.apiError(httpResponse.statusCode,
                                            "Claude Code OAuth token required — get it from claude.ai after logging in with Claude Code")
        case 404:
            throw ProviderAPIError.apiError(404,
                                            "Anthropic usage endpoint unavailable — enable Demo Mode in Settings for offline demo")
        case 429:
            throw ProviderAPIError.rateLimited
        default:
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw ProviderAPIError.apiError(httpResponse.statusCode, body.prefix(200).description)
        }

        do {
            let usage = try JSONDecoder().decode(AnthropicOAuthUsageResponse.self, from: data)
            let tier = usage.rateLimitTier ?? "unknown"
            let primary = RateWindow(
                usedPercent: 0,
                windowMinutes: nil,
                resetsAt: nil,
                resetDescription: "Rate limit tier: \(tier)"
            )
            return ProviderUsageSnapshot(
                provider: .anthropic,
                primary: primary,
                secondary: nil,
                totalTokens: usage.sevenDay,
                totalCostUSD: 0.0,
                balance: nil,
                dailyUsage: [],
                updatedAt: Date()
            )
        } catch {
            throw ProviderAPIError.parseError("Anthropic OAuth response: \(error.localizedDescription)")
        }
    }
}

struct AnthropicOAuthUsageResponse: Decodable {
    let sevenDay: Int
    let rateLimitTier: String?

    private enum CodingKeys: String, CodingKey {
        case sevenDay = "seven_day"
        case rateLimitTier = "rate_limit_tier"
    }
}
