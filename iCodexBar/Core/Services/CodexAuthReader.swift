import Foundation

// MARK: - Credentials

public struct CodexAuthCredentials: Sendable {
    public let accessToken: String
    public let accountId: String?

    public init(accessToken: String, accountId: String?) {
        self.accessToken = accessToken
        self.accountId = accountId
    }
}

// MARK: - Errors

public enum CodexAuthError: Error, LocalizedError {
    case authFileMissing
    case authFileUnreadable(Error)
    case authFileMalformed(String)
    case noAccessToken

    public var errorDescription: String? {
        switch self {
        case .authFileMissing:
            "Codex auth file not found. Run `codex login` to authenticate."
        case let .authFileUnreadable(error):
            "Could not read Codex auth file: \(error.localizedDescription)"
        case let .authFileMalformed(detail):
            "Codex auth file is malformed: \(detail)"
        case .noAccessToken:
            "No access token found in Codex auth file. Run `codex login` to authenticate."
        }
    }
}

// MARK: - Reader

public enum CodexAuthReader {
    // MARK: - Public API

    /// Reads Codex credentials from ~/.codex/auth.json (or $CODEX_HOME/auth.json).
    public static func read(
        env: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> CodexAuthCredentials {
        let authURL = authFileURL(env: env)

        guard FileManager.default.fileExists(atPath: authURL.path) else {
            throw CodexAuthError.authFileMissing
        }

        let data: Data
        do {
            data = try Data(contentsOf: authURL)
        } catch {
            throw CodexAuthError.authFileUnreadable(error)
        }

        return try parse(data: data)
    }

    /// Returns the resolved chatgpt base URL, honouring $CODEX_HOME and config.toml overrides.
    public static func chatGPTBaseURL(
        env: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL {
        let configURL = configFileURL(env: env)
        if let contents = try? String(contentsOf: configURL, encoding: .utf8),
           let raw = parseChatGPTBaseURL(from: contents)
        {
            let normalized = normalizeChatGPTBaseURL(raw)
            if let url = URL(string: normalized) {
                return url
            }
        }
        return URL(string: "https://chatgpt.com/backend-api")!
    }

    // MARK: - Internal helpers (internal for tests)

    static func parse(data: Data) throws -> CodexAuthCredentials {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CodexAuthError.authFileMalformed("Root value is not a JSON object")
        }

        // Support legacy API-key-only format
        if let apiKey = json["OPENAI_API_KEY"] as? String,
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return CodexAuthCredentials(accessToken: apiKey, accountId: nil)
        }

        guard let tokens = json["tokens"] as? [String: Any] else {
            throw CodexAuthError.authFileMalformed("Missing `tokens` object")
        }

        guard let accessToken = stringValue(in: tokens, keys: ["access_token", "accessToken"]),
              !accessToken.isEmpty
        else {
            throw CodexAuthError.noAccessToken
        }

        let accountId = stringValue(in: tokens, keys: ["account_id", "accountId"])
        return CodexAuthCredentials(accessToken: accessToken, accountId: accountId)
    }

    // MARK: - Private helpers

    private static func authFileURL(env: [String: String]) -> URL {
        codexHomeURL(env: env).appendingPathComponent("auth.json")
    }

    private static func configFileURL(env: [String: String]) -> URL {
        codexHomeURL(env: env).appendingPathComponent("config.toml")
    }

    private static func codexHomeURL(env: [String: String]) -> URL {
        if let codexHome = env["CODEX_HOME"],
           !codexHome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return URL(fileURLWithPath: codexHome)
        }
        #if os(macOS)
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        #else
        // On iOS, ~/.codex does not exist; callers handle the auth-file-missing error.
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex")
        #endif
    }

    /// Line-based toml scanner -- matches CodexBar's parseChatGPTBaseURL semantics.
    static func parseChatGPTBaseURL(from contents: String) -> String? {
        for rawLine in contents.split(whereSeparator: \.isNewline) {
            // Strip inline comments
            let commentStripped = rawLine.split(
                separator: "#",
                maxSplits: 1,
                omittingEmptySubsequences: true
            ).first ?? rawLine[rawLine.startIndex...]
            let trimmed = commentStripped.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard key == "chatgpt_base_url" else { continue }

            var value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            // Strip surrounding quotes
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'"))
            {
                value = String(value.dropFirst().dropLast())
            }
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private static func normalizeChatGPTBaseURL(_ value: String) -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "https://chatgpt.com/backend-api" }
        // Remove trailing slashes
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        // If it's a chat host without a path, append /backend-api
        if (trimmed.hasPrefix("https://chatgpt.com") || trimmed.hasPrefix("https://chat.openai.com")),
           !trimmed.contains("/backend-api")
        {
            trimmed += "/backend-api"
        }
        return trimmed
    }

    private static func stringValue(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
