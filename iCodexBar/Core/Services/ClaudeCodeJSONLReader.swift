import Foundation

// MARK: - Errors

public enum ClaudeCodeJSONLError: Error, LocalizedError {
    case directoryNotFound

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            "Claude Code session directory not found at ~/.claude/projects."
        }
    }
}

// MARK: - Reader

public enum ClaudeCodeJSONLReader {
    /// User home directory. `homeDirectoryForCurrentUser` is macOS-only; iOS gets a
    /// path that won't contain a real Claude install (the reader will throw
    /// `directoryNotFound`, which is the right behavior — Claude Code isn't on iOS).
    private static var defaultHome: URL {
        #if os(macOS)
            FileManager.default.homeDirectoryForCurrentUser
        #else
            URL(fileURLWithPath: NSHomeDirectory())
        #endif
    }

    /// Builds a snapshot from `~/.claude/projects/<encoded-project>/<session>.jsonl`.
    /// `homeDirectory` and `now` are injectable for tests.
    public static func read(
        homeDirectory: URL? = nil,
        now: Date = Date(),
        plan: ClaudeCodePlan = .max20x
    ) throws -> ProviderUsageSnapshot {
        let homeDirectory = homeDirectory ?? defaultHome
        let projectsURL = homeDirectory
            .appendingPathComponent(".claude")
            .appendingPathComponent("projects")

        var isDir: ObjCBool = false
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectsURL.path, isDirectory: &isDir), isDir.boolValue else {
            throw ClaudeCodeJSONLError.directoryNotFound
        }

        let weekAgo = now.addingTimeInterval(-7 * 24 * 3_600)
        let fiveHoursAgo = now.addingTimeInterval(-5 * 3_600)

        let jsonlFiles = enumerateRecentJSONL(in: projectsURL, modifiedAfter: weekAgo)

        // Aggregate
        var sessionTokens = 0
        var weeklyTokens = 0
        var totalRawTokens = 0
        var totalCost: Double = 0
        var perDayBillable: [String: Int] = [:]
        var perDayCost: [String: Double] = [:]
        var perDayInput: [String: Int] = [:]
        var perDayOutput: [String: Int] = [:]

        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: "en_US_POSIX")
        dayFmt.dateFormat = "yyyy-MM-dd"
        dayFmt.timeZone = TimeZone.current

        for fileURL in jsonlFiles {
            guard let raw = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
                guard let data = line.data(using: .utf8) else { continue }
                guard let record = try? JSONDecoder().decode(ClaudeCodeRecord.self, from: data) else {
                    continue
                }
                guard record.type == "assistant",
                      let usage = record.message?.usage,
                      let timestamp = record.timestamp,
                      timestamp >= weekAgo
                else { continue }

                let billable = usage.weightedBillableTokens
                let raw = usage.inputTokens + usage.cacheCreationInputTokens
                    + usage.cacheReadInputTokens + usage.outputTokens
                let cost = ClaudeCodePricing.costUSD(for: usage, model: record.message?.model)

                weeklyTokens += billable
                totalRawTokens += raw
                totalCost += cost
                if timestamp >= fiveHoursAgo {
                    sessionTokens += billable
                }
                let dayKey = dayFmt.string(from: timestamp)
                perDayBillable[dayKey, default: 0] += billable
                perDayCost[dayKey, default: 0] += cost
                perDayInput[dayKey, default: 0] += usage.inputTokens + usage.cacheCreationInputTokens
                    + usage.cacheReadInputTokens
                perDayOutput[dayKey, default: 0] += usage.outputTokens
            }
        }

        let primary = RateWindow(
            usedPercent: percent(used: sessionTokens, quota: plan.sessionTokenQuota),
            windowMinutes: 300,
            resetsAt: fiveHoursAgo.addingTimeInterval(5 * 3_600),
            resetDescription: "in 5h" // rolling — descriptive only
        )
        let secondary = RateWindow(
            usedPercent: percent(used: weeklyTokens, quota: plan.weeklyTokenQuota),
            windowMinutes: 7 * 24 * 60,
            resetsAt: weekAgo.addingTimeInterval(7 * 24 * 3_600),
            resetDescription: "in 7d"
        )

        let dailyUsage: [DailyUsageEntry] = perDayBillable.keys.sorted().map { day in
            DailyUsageEntry(
                date: day,
                totalTokens: perDayBillable[day],
                costUSD: perDayCost[day],
                inputTokens: perDayInput[day],
                outputTokens: perDayOutput[day]
            )
        }

        return ProviderUsageSnapshot(
            provider: .claudeCode,
            primary: primary,
            secondary: secondary,
            totalTokens: totalRawTokens,
            totalCostUSD: totalCost,
            balance: nil,
            dailyUsage: dailyUsage,
            updatedAt: now
        )
    }

    // MARK: - Private helpers

    private static func enumerateRecentJSONL(in projectsDir: URL, modifiedAfter cutoff: Date) -> [URL] {
        let fileManager = FileManager.default
        guard let projectDirs = try? fileManager.contentsOfDirectory(
            at: projectsDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var result: [URL] = []
        for projectDir in projectDirs {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: projectDir.path, isDirectory: &isDir), isDir.boolValue
            else { continue }
            guard let files = try? fileManager.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for file in files where file.pathExtension == "jsonl" {
                let mtime = (try? file.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate) ?? .distantPast
                if mtime >= cutoff {
                    result.append(file)
                }
            }
        }
        return result
    }

    private static func percent(used: Int, quota: Int) -> Double {
        guard quota > 0 else { return 0 }
        return min(100, max(0, Double(used) / Double(quota) * 100))
    }
}
