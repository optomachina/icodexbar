import XCTest
@testable import iCodexBar

final class UsageFormatterTests: XCTestCase {

    // MARK: - Token Formatting Tests

    func testFormatTokensLessThanThousand() {
        XCTAssertEqual(UsageFormatter.formatTokens(999), "999")
    }

    func testFormatTokensExactlyOneThousand() {
        XCTAssertEqual(UsageFormatter.formatTokens(1000), "1K")
    }

    func testFormatTokensThousands() {
        XCTAssertEqual(UsageFormatter.formatTokens(456789), "457K")
    }

    func testFormatTokensExactlyOneMillion() {
        XCTAssertEqual(UsageFormatter.formatTokens(1_000_000), "1M")
    }

    func testFormatTokensMillions() {
        let result = UsageFormatter.formatTokens(1_234_567)
        XCTAssertTrue(result.hasSuffix("M"))
    }

    func testFormatTokensZero() {
        XCTAssertEqual(UsageFormatter.formatTokens(0), "0")
    }

    // MARK: - USD Formatting Tests

    func testFormatUSDSmall() {
        XCTAssertEqual(UsageFormatter.formatUSD(4.32), "$4.32")
    }

    func testFormatUSDLarge() {
        XCTAssertEqual(UsageFormatter.formatUSD(1234.56), "$1,234.56")
    }

    // MARK: - Percentage Formatting Tests

    func testFormatPercentRoundsUp() {
        XCTAssertEqual(UsageFormatter.formatPercent(42.5), "43%")
    }

    func testFormatPercentRoundsDown() {
        XCTAssertEqual(UsageFormatter.formatPercent(42.4), "42%")
    }

    func testFormatPercentExactlyWhole() {
        XCTAssertEqual(UsageFormatter.formatPercent(50.0), "50%")
    }

    func testFormatPercentZero() {
        XCTAssertEqual(UsageFormatter.formatPercent(0.0), "0%")
    }

    func testFormatPercentHundred() {
        XCTAssertEqual(UsageFormatter.formatPercent(100.0), "100%")
    }

    // MARK: - Relative Date Formatting Tests

    func testFormatRelativeDateJustNow() {
        let date = Date().addingTimeInterval(-30)
        XCTAssertEqual(UsageFormatter.formatRelativeDate(date), "just now")
    }

    func testFormatRelativeDateMinutesAgo() {
        let date = Date().addingTimeInterval(-120) // 2 minutes
        XCTAssertEqual(UsageFormatter.formatRelativeDate(date), "2m ago")
    }

    func testFormatRelativeDateHoursAgo() {
        let date = Date().addingTimeInterval(-7200) // 2 hours
        XCTAssertEqual(UsageFormatter.formatRelativeDate(date), "2h ago")
    }

    func testFormatRelativeDateYesterday() {
        let date = Date().addingTimeInterval(-86400) // 1 day
        XCTAssertEqual(UsageFormatter.formatRelativeDate(date), "yesterday")
    }

    func testFormatRelativeDateDaysAgo() {
        let date = Date().addingTimeInterval(-259200) // 3 days
        XCTAssertEqual(UsageFormatter.formatRelativeDate(date), "3d ago")
    }

    // MARK: - Days Remaining Tests

    func testDaysRemainingFuture() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        XCTAssertEqual(UsageFormatter.daysRemaining(in: futureDate), 5)
    }

    func testDaysRemainingPast() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        XCTAssertLessThanOrEqual(UsageFormatter.daysRemaining(in: pastDate), 0)
    }

    func testDaysRemainingToday() {
        XCTAssertEqual(UsageFormatter.daysRemaining(in: Date()), 0)
    }

    // MARK: - Format Days Remaining String Tests

    func testFormatDaysRemainingZero() {
        XCTAssertEqual(UsageFormatter.formatDaysRemaining(0), "ended")
    }

    func testFormatDaysRemainingNegative() {
        XCTAssertEqual(UsageFormatter.formatDaysRemaining(-5), "ended")
    }

    func testFormatDaysRemainingOne() {
        XCTAssertEqual(UsageFormatter.formatDaysRemaining(1), "1 day left")
    }

    func testFormatDaysRemainingMultiple() {
        XCTAssertEqual(UsageFormatter.formatDaysRemaining(5), "5 days left")
    }

    // MARK: - Tokens and Cost Combined Tests

    func testFormatTokensAndCostBothPresent() {
        let result = UsageFormatter.formatTokensAndCost(tokens: 1000, cost: 5.50)
        XCTAssertTrue(result.contains("1K"))
        XCTAssertTrue(result.contains("$5.50"))
    }

    func testFormatTokensAndCostNoTokens() {
        let result = UsageFormatter.formatTokensAndCost(tokens: nil, cost: 5.50)
        XCTAssertTrue(result.contains("—"))
        XCTAssertTrue(result.contains("$5.50"))
    }

    func testFormatTokensAndCostNoCost() {
        let result = UsageFormatter.formatTokensAndCost(tokens: 1000, cost: nil)
        XCTAssertTrue(result.contains("1K"))
        XCTAssertTrue(result.contains("—"))
    }

    func testFormatTokensAndCostNeither() {
        let result = UsageFormatter.formatTokensAndCost(tokens: nil, cost: nil)
        XCTAssertEqual(result, "— tokens · —")
    }
}
