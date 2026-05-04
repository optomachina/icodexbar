import Foundation
import iCodexBarCore

/// Fetches Codex CLI usage on demand and on a background timer.
/// Published state is read by StatusItemController on the main actor.
@MainActor
final class CodexUsageRefresher {
    private(set) var snapshots: [ProviderUsageSnapshot] = []
    private(set) var lastErrorMessage: String?

    /// Async stream that fires whenever state changes.
    let (changeStream, changeContinuation) = AsyncStream<Void>.makeStream()

    private let api = CodexUsageAPI()

    // MARK: - Refresh

    func refresh() async {
        do {
            let credentials = try CodexAuthReader.read()
            let response = try await api.fetchUsage(credentials: credentials)
            let snapshot = response.toSnapshot()
            snapshots = [snapshot]
            lastErrorMessage = nil
        } catch let authErr as CodexAuthError {
            snapshots = []
            switch authErr {
            case .authFileMissing:
                lastErrorMessage = "Codex CLI: not signed in. Run `codex login`."
            case .noAccessToken:
                lastErrorMessage = "Codex CLI: token expired. Run `codex login` to refresh."
            default:
                lastErrorMessage = "Codex CLI: \(authErr.localizedDescription)"
            }
        } catch let usageErr as CodexUsageError {
            switch usageErr {
            case .unauthorized:
                lastErrorMessage = "Codex CLI: token expired. Run `codex login` to refresh."
            case .networkError:
                // Preserve last known data on network error
                lastErrorMessage = "Codex CLI: network error"
            default:
                lastErrorMessage = "Codex CLI: \(usageErr.localizedDescription)"
            }
        } catch {
            lastErrorMessage = "Codex CLI: \(error.localizedDescription)"
        }
        changeContinuation.yield()
    }
}
