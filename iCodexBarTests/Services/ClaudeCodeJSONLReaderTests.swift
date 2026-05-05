@testable import iCodexBarCore
import XCTest

final class ClaudeCodeJSONLReaderTests: XCTestCase {
    private var tempHome: URL!
    private var projectsDir: URL!
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    override func setUpWithError() throws {
        tempHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("icodexbar-claude-tests-\(UUID().uuidString)")
        projectsDir = tempHome.appendingPathComponent(".claude").appendingPathComponent("projects")
        try FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempHome)
    }

    // MARK: - Directory handling

    func testThrowsWhenProjectsDirectoryMissing() throws {
        let bareHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("icodexbar-claude-bare-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: bareHome, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bareHome) }

        XCTAssertThrowsError(try ClaudeCodeJSONLReader.read(homeDirectory: bareHome)) { err in
            guard case ClaudeCodeJSONLError.directoryNotFound = err else {
                return XCTFail("Expected directoryNotFound, got \(err)")
            }
        }
    }

    func testEmptyProjectsDirectoryReturnsZeroSnapshot() throws {
        let now = Date()
        let snap = try ClaudeCodeJSONLReader.read(homeDirectory: tempHome, now: now)
        XCTAssertEqual(snap.provider, .claudeCode)
        XCTAssertEqual(snap.totalTokens, 0)
        XCTAssertEqual(snap.totalCostUSD ?? -1, 0, accuracy: 0.0001)
        XCTAssertTrue(snap.dailyUsage.isEmpty)
        XCTAssertEqual(snap.primary?.usedPercent ?? -1, 0)
    }

    // MARK: - Per-record parsing

    func testIgnoresNonAssistantRecords() throws {
        let now = Date()
        let lines = [
            assistantLine(at: now, model: "claude-opus-4-7", input: 100, cacheCreate: 0, cacheRead: 0, output: 50),
            userLine(at: now),
            attachmentLine(at: now),
            queueOperationLine(at: now)
        ]
        try writeSession(lines: lines, in: "proj-a")

        let snap = try ClaudeCodeJSONLReader.read(
            homeDirectory: tempHome, now: now, plan: .max20x
        )

        // Only the one assistant record counted: 100 input + 50 output = 150 raw tokens
        XCTAssertEqual(snap.totalTokens, 150)
    }

    func testTolerantOfMalformedLines() throws {
        let now = Date()
        let lines = [
            assistantLine(at: now, model: "claude-opus-4-7", input: 10, cacheCreate: 0, cacheRead: 0, output: 5),
            "not json at all",
            assistantLine(at: now, model: "claude-opus-4-7", input: 20, cacheCreate: 0, cacheRead: 0, output: 7)
        ]
        try writeSession(lines: lines, in: "proj-a")

        let snap = try ClaudeCodeJSONLReader.read(homeDirectory: tempHome, now: now)
        XCTAssertEqual(snap.totalTokens, 10 + 5 + 20 + 7)
    }

    // MARK: - Token math

    func testWeightedBillableTokenMath() {
        let usage = ClaudeCodeRecord.Usage.fromValues(
            input: 100, cacheCreate: 1000, cacheRead: 10_000, output: 200
        )
        // weighted = 100 + 1000*0.25 + 10000*0.10 + 200 = 100 + 250 + 1000 + 200 = 1550
        XCTAssertEqual(usage.weightedBillableTokens, 1550)
    }

    // MARK: - Window aggregation

    func testSessionWindowExcludesRecordsOlderThanFiveHours() throws {
        let now = Date()
        let recent = now.addingTimeInterval(-30 * 60) // 30 min ago — in session
        let oldButThisWeek = now.addingTimeInterval(-6 * 3600) // 6h ago — not session, in week
        let lines = [
            assistantLine(at: recent, model: "claude-opus-4-7",
                          input: 100, cacheCreate: 0, cacheRead: 0, output: 50),
            assistantLine(at: oldButThisWeek, model: "claude-opus-4-7",
                          input: 200, cacheCreate: 0, cacheRead: 0, output: 100)
        ]
        try writeSession(lines: lines, in: "proj-a")

        let snap = try ClaudeCodeJSONLReader.read(
            homeDirectory: tempHome, now: now, plan: .max20x
        )

        // Session: only 150 weighted tokens (recent record).
        // Weekly: 450 weighted tokens (both).
        let sessionUsed = snap.primary?.usedPercent ?? 0
        let weeklyUsed = snap.secondary?.usedPercent ?? 0
        XCTAssertEqual(sessionUsed, 150.0 / Double(ClaudeCodePlan.max20x.sessionTokenQuota) * 100, accuracy: 0.0001)
        XCTAssertEqual(weeklyUsed, 450.0 / Double(ClaudeCodePlan.max20x.weeklyTokenQuota) * 100, accuracy: 0.0001)
    }

    func testWeeklyWindowExcludesRecordsOlderThanSevenDays() throws {
        let now = Date()
        let in_window = now.addingTimeInterval(-2 * 24 * 3600)
        let out_of_window = now.addingTimeInterval(-8 * 24 * 3600)
        let lines = [
            assistantLine(at: in_window, model: "claude-opus-4-7",
                          input: 100, cacheCreate: 0, cacheRead: 0, output: 50),
            assistantLine(at: out_of_window, model: "claude-opus-4-7",
                          input: 999, cacheCreate: 0, cacheRead: 0, output: 999)
        ]
        try writeSession(lines: lines, in: "proj-a")

        let snap = try ClaudeCodeJSONLReader.read(homeDirectory: tempHome, now: now)
        XCTAssertEqual(snap.totalTokens, 150) // older record dropped
    }

    func testAggregatesAcrossMultipleProjects() throws {
        let now = Date()
        try writeSession(lines: [
            assistantLine(at: now, model: "claude-opus-4-7",
                          input: 100, cacheCreate: 0, cacheRead: 0, output: 50)
        ], in: "project-one")
        try writeSession(lines: [
            assistantLine(at: now, model: "claude-sonnet-4-6",
                          input: 200, cacheCreate: 0, cacheRead: 0, output: 100)
        ], in: "project-two")

        let snap = try ClaudeCodeJSONLReader.read(homeDirectory: tempHome, now: now)
        XCTAssertEqual(snap.totalTokens, 100 + 50 + 200 + 100)
        // Expect at least one daily entry covering today
        XCTAssertGreaterThan(snap.dailyUsage.count, 0)
    }

    // MARK: - Pricing

    func testCostCalculationOpusVsSonnet() {
        let opusUsage = ClaudeCodeRecord.Usage.fromValues(
            input: 1_000_000, cacheCreate: 0, cacheRead: 0, output: 1_000_000
        )
        let opusCost = ClaudeCodePricing.costUSD(for: opusUsage, model: "claude-opus-4-7")
        // 1M input * $15 + 1M output * $75 = $90
        XCTAssertEqual(opusCost, 90.0, accuracy: 0.001)

        let sonnetCost = ClaudeCodePricing.costUSD(for: opusUsage, model: "claude-sonnet-4-6")
        // 1M input * $3 + 1M output * $15 = $18
        XCTAssertEqual(sonnetCost, 18.0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func writeSession(lines: [String], in projectName: String) throws {
        let projDir = projectsDir.appendingPathComponent(projectName)
        try FileManager.default.createDirectory(at: projDir, withIntermediateDirectories: true)
        let file = projDir.appendingPathComponent("\(UUID().uuidString).jsonl")
        let contents = lines.joined(separator: "\n") + "\n"
        try contents.write(to: file, atomically: true, encoding: .utf8)
    }

    private func assistantLine(
        at date: Date,
        model: String,
        input: Int,
        cacheCreate: Int,
        cacheRead: Int,
        output: Int
    ) -> String {
        let ts = iso.string(from: date)
        return """
        {"type":"assistant","timestamp":"\(ts)","sessionId":"abc","message":{"model":"\(
            model
        )","usage":{"input_tokens":\(input),"cache_creation_input_tokens":\(cacheCreate),"cache_read_input_tokens":\(
            cacheRead
        ),"output_tokens":\(output)}}}
        """
    }

    private func userLine(at date: Date) -> String {
        let ts = iso.string(from: date)
        return """
        {"type":"user","timestamp":"\(ts)","sessionId":"abc","message":{"role":"user","content":"hi"}}
        """
    }

    private func attachmentLine(at date: Date) -> String {
        let ts = iso.string(from: date)
        return """
        {"type":"attachment","timestamp":"\(ts)","attachment":{"type":"todo_reminder"}}
        """
    }

    private func queueOperationLine(at date: Date) -> String {
        let ts = iso.string(from: date)
        return """
        {"type":"queue-operation","timestamp":"\(ts)","operation":"enqueue","content":"/loop"}
        """
    }
}

/// Test-only convenience constructor for Usage (Decodable-only struct).
private extension ClaudeCodeRecord.Usage {
    static func fromValues(input: Int, cacheCreate: Int, cacheRead: Int, output: Int) -> Self {
        let json = """
        {"input_tokens":\(input),"cache_creation_input_tokens":\(cacheCreate),"cache_read_input_tokens":\(
            cacheRead
        ),"output_tokens":\(output)}
        """
        return try! JSONDecoder().decode(Self.self, from: Data(json.utf8))
    }
}
