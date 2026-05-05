import Foundation
import iCodexBarCore

/// Fetches all macOS-local provider usage on demand and on a background timer.
/// Published state is read by StatusItemController on the main actor.
@MainActor
final class MacUsageRefresher {
    private(set) var snapshots: [ProviderUsageSnapshot] = []
    private(set) var lastErrorMessage: String?

    /// Async stream that fires whenever state changes.
    let (changeStream, changeContinuation) = AsyncStream<Void>.makeStream()

    private let codexAPI = CodexUsageAPI()
    private let anthropicAPI = AnthropicUsageAPI.shared

    // MARK: - Refresh

    func refresh(interaction: ProviderInteraction = .background) async {
        async let codex: (snap: ProviderUsageSnapshot?, err: String?) = fetchCodex()
        async let claude: (snap: ProviderUsageSnapshot?, err: String?) = fetchClaude(interaction: interaction)
        let (c, cl) = await (codex, claude)

        snapshots = [c.snap, cl.snap].compactMap { $0 }
        let errs = [c.err, cl.err].compactMap { $0 }
        lastErrorMessage = errs.isEmpty ? nil : errs.joined(separator: "\n")
        changeContinuation.yield()
    }

    // MARK: - Per-provider fetches

    private func fetchCodex() async -> (snap: ProviderUsageSnapshot?, err: String?) {
        do {
            let credentials = try CodexAuthReader.read()
            let response = try await codexAPI.fetchUsage(credentials: credentials)
            return (response.toSnapshot(), nil)
        } catch let authErr as CodexAuthError {
            switch authErr {
            case .authFileMissing:
                return (nil, "Codex CLI: not signed in. Run `codex login`.")
            case .noAccessToken:
                return (nil, "Codex CLI: token expired. Run `codex login` to refresh.")
            default:
                return (nil, "Codex CLI: \(authErr.localizedDescription)")
            }
        } catch let usageErr as CodexUsageError {
            switch usageErr {
            case .unauthorized:
                return (nil, "Codex CLI: token expired. Run `codex login` to refresh.")
            case .networkError:
                return (nil, "Codex CLI: network error")
            default:
                return (nil, "Codex CLI: \(usageErr.localizedDescription)")
            }
        } catch {
            return (nil, "Codex CLI: \(error.localizedDescription)")
        }
    }

    private func fetchClaude(
        interaction: ProviderInteraction
    ) async -> (snap: ProviderUsageSnapshot?, err: String?) {
        // Tier comes from Keychain when available; falls back to .max20x.
        // Background reads after a denial throw .backgroundReadGated silently — we'll
        // still return a JSONL-only snapshot in that case.
        let credentials = try? ClaudeCodeKeychainReader.read(interaction: interaction)
        let plan = credentials?.inferredPlan ?? .max20x

        // JSONL gives us cost / daily detail / token totals (always available locally).
        let jsonlSnap: ProviderUsageSnapshot?
        let jsonlErr: String?
        do {
            jsonlSnap = try ClaudeCodeJSONLReader.read(plan: plan)
            jsonlErr = nil
        } catch ClaudeCodeJSONLError.directoryNotFound {
            jsonlSnap = nil
            jsonlErr = "Claude Code: no session logs at ~/.claude/projects."
        } catch {
            jsonlSnap = nil
            jsonlErr = "Claude Code: \(error.localizedDescription)"
        }

        // OAuth gives authoritative quota %s. If the call fails, fall back to JSONL-derived %s.
        guard let credentials else {
            // No credentials → return JSONL-only snapshot (with fallback plan).
            return (jsonlSnap, jsonlErr)
        }

        do {
            let oauthSnap = try await anthropicAPI.fetchUsage(apiKey: credentials.accessToken)
            let merged = ProviderUsageSnapshot(
                provider: .claudeCode,
                primary: oauthSnap.primary,
                secondary: oauthSnap.secondary,
                totalTokens: jsonlSnap?.totalTokens,
                totalCostUSD: jsonlSnap?.totalCostUSD,
                balance: nil,
                dailyUsage: jsonlSnap?.dailyUsage ?? [],
                updatedAt: Date()
            )
            return (merged, nil)
        } catch {
            // OAuth failed — return JSONL snapshot if we have it, otherwise surface the error.
            if let jsonlSnap {
                return (jsonlSnap, nil)
            }
            return (nil, "Claude Code: \(error.localizedDescription)")
        }
    }
}
