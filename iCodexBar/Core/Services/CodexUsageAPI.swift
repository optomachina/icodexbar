import Foundation

// MARK: - Response types

public struct CodexUsageResponse: Decodable, Sendable {
    public let planType: String?
    public let rateLimit: RateLimitDetails?
    public let credits: CreditDetails?

    public struct RateLimitDetails: Decodable, Sendable {
        public let primaryWindow: WindowSnapshot?
        public let secondaryWindow: WindowSnapshot?

        enum CodingKeys: String, CodingKey {
            case primaryWindow = "primary_window"
            case secondaryWindow = "secondary_window"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.primaryWindow = try? container.decodeIfPresent(WindowSnapshot.self, forKey: .primaryWindow)
            self.secondaryWindow = try? container.decodeIfPresent(WindowSnapshot.self, forKey: .secondaryWindow)
        }
    }

    public struct WindowSnapshot: Decodable, Sendable {
        /// Percent of quota used (0-100). Stored as Double for pace math, API may return Int.
        public let usedPercent: Double
        /// Unix epoch seconds when this window resets.
        public let resetAt: Int
        /// Window duration in seconds (18000 = 5h, 604800 = weekly).
        public let limitWindowSeconds: Int

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case resetAt = "reset_at"
            case limitWindowSeconds = "limit_window_seconds"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Accept both Int and Double from the wire
            if let intVal = try? container.decode(Int.self, forKey: .usedPercent) {
                self.usedPercent = Double(intVal)
            } else {
                self.usedPercent = (try? container.decode(Double.self, forKey: .usedPercent)) ?? 0
            }
            self.resetAt = (try? container.decode(Int.self, forKey: .resetAt)) ?? 0
            self.limitWindowSeconds = (try? container.decode(Int.self, forKey: .limitWindowSeconds)) ?? 0
        }
    }

    public struct CreditDetails: Decodable, Sendable {
        public let hasCredits: Bool
        public let unlimited: Bool
        public let balance: Double?

        enum CodingKeys: String, CodingKey {
            case hasCredits = "has_credits"
            case unlimited
            case balance
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.hasCredits = (try? container.decode(Bool.self, forKey: .hasCredits)) ?? false
            self.unlimited = (try? container.decode(Bool.self, forKey: .unlimited)) ?? false
            // balance may be a number or a stringified number
            if let d = try? container.decode(Double.self, forKey: .balance) {
                self.balance = d
            } else if let s = try? container.decode(String.self, forKey: .balance), let d = Double(s) {
                self.balance = d
            } else {
                self.balance = nil
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case credits
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.planType = try? container.decodeIfPresent(String.self, forKey: .planType)
        self.rateLimit = try? container.decodeIfPresent(RateLimitDetails.self, forKey: .rateLimit)
        self.credits = try? container.decodeIfPresent(CreditDetails.self, forKey: .credits)
    }
}

// MARK: - Errors

public enum CodexUsageError: Error, LocalizedError {
    case unauthorized
    case invalidResponse
    case serverError(Int, String?)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Codex token expired or invalid. Run `codex login` to re-authenticate."
        case .invalidResponse:
            return "Invalid response from Codex usage API."
        case let .serverError(code, message):
            if let message, !message.isEmpty {
                return "Codex API error \(code): \(message)"
            }
            return "Codex API error \(code)."
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Client

public struct CodexUsageAPI: Sendable {
    private static let usagePath = "/wham/usage"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches current usage. Throws `CodexUsageError` on failure.
    public func fetchUsage(
        credentials: CodexAuthCredentials,
        env: [String: String] = ProcessInfo.processInfo.environment
    ) async throws -> CodexUsageResponse {
        let baseURL = CodexAuthReader.chatGPTBaseURL(env: env)
        let url = baseURL.appendingPathComponent(Self.usagePath)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("iCodexBar", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accountId = credentials.accountId, !accountId.isEmpty {
            request.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CodexUsageError.invalidResponse
            }

            switch http.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(CodexUsageResponse.self, from: data)
                } catch {
                    throw CodexUsageError.invalidResponse
                }
            case 401, 403:
                throw CodexUsageError.unauthorized
            default:
                let body = String(data: data, encoding: .utf8)
                throw CodexUsageError.serverError(http.statusCode, body)
            }
        } catch let error as CodexUsageError {
            throw error
        } catch {
            throw CodexUsageError.networkError(error)
        }
    }
}

// MARK: - Conversion to ProviderUsageSnapshot

extension CodexUsageResponse {
    /// Maps this response into the shared ProviderUsageSnapshot model.
    public func toSnapshot(updatedAt: Date = Date()) -> ProviderUsageSnapshot {
        var primaryWindow: RateWindow?
        var secondaryWindow: RateWindow?

        if let window = rateLimit?.primaryWindow {
            let resetsAt = Date(timeIntervalSince1970: TimeInterval(window.resetAt))
            let minutes = window.limitWindowSeconds / 60
            primaryWindow = RateWindow(
                usedPercent: window.usedPercent,
                windowMinutes: minutes,
                resetsAt: resetsAt,
                resetDescription: resetDescription(for: resetsAt)
            )
        }

        if let window = rateLimit?.secondaryWindow {
            let resetsAt = Date(timeIntervalSince1970: TimeInterval(window.resetAt))
            let minutes = window.limitWindowSeconds / 60
            secondaryWindow = RateWindow(
                usedPercent: window.usedPercent,
                windowMinutes: minutes,
                resetsAt: resetsAt,
                resetDescription: resetDescription(for: resetsAt)
            )
        }

        return ProviderUsageSnapshot(
            provider: .codexCLI,
            primary: primaryWindow,
            secondary: secondaryWindow,
            totalTokens: nil,
            totalCostUSD: nil,
            balance: credits?.balance,
            dailyUsage: [],
            updatedAt: updatedAt
        )
    }

    private func resetDescription(for date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "now" }
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "in \(hours)h \(remainingMinutes)m"
        }
        return "in \(minutes)m"
    }
}
