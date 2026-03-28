import XCTest
@testable import iCodexBar

final class CurrencyFormatterTests: XCTestCase {

    // MARK: - Basic Formatting Tests

    func testFormatZero() {
        XCTAssertEqual(CurrencyFormatter.format(0.0), "$0.00")
    }

    func testFormatSmallAmount() {
        XCTAssertEqual(CurrencyFormatter.format(4.32), "$4.32")
    }

    func testFormatLargeAmount() {
        XCTAssertEqual(CurrencyFormatter.format(1234.56), "$1,234.56")
    }

    func testFormatWithCents() {
        XCTAssertEqual(CurrencyFormatter.format(0.01), "$0.01")
    }

    func testFormatWholeDollar() {
        XCTAssertEqual(CurrencyFormatter.format(100.0), "$100.00")
    }

    // MARK: - Compact Formatting Tests

    func testFormatCompactThousands() {
        XCTAssertEqual(CurrencyFormatter.formatCompact(1500.0), "$1.5K")
    }

    func testFormatCompactMillions() {
        XCTAssertEqual(CurrencyFormatter.formatCompact(2_500_000.0), "$2.5M")
    }

    func testFormatCompactSmall() {
        XCTAssertEqual(CurrencyFormatter.formatCompact(500.0), "$500.00")
    }

    func testFormatCompactExactThousand() {
        XCTAssertEqual(CurrencyFormatter.formatCompact(1000.0), "$1.0K")
    }

    func testFormatCompactExactMillion() {
        XCTAssertEqual(CurrencyFormatter.formatCompact(1_000_000.0), "$1.0M")
    }

    // MARK: - Edge Cases

    func testFormatNegativeAmount() {
        let result = CurrencyFormatter.format(-10.50)
        // Negative amounts should still format (shows as -$10.50)
        XCTAssertTrue(result.contains("10.50"))
    }

    func testFormatVeryLargeAmount() {
        let result = CurrencyFormatter.format(1_000_000_000.0)
        XCTAssertTrue(result.contains("$"))
    }
}
