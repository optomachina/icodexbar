@testable import iCodexBarCore
import XCTest

/// Fixture-backed decoder coverage for OpenAI cost responses.
final class OpenAIDecoderTests: XCTestCase {
    /// Verifies the baseline OpenAI costs fixture decodes one daily bucket.
    func testCostsBasicDecodesSingleBucket() throws {
        let decoded = try FixtureLoader.decode(OpenAICostsResponse.self, from: "OpenAI/costs_basic")

        XCTAssertEqual(decoded.data.count, 1)

        let bucket = try XCTUnwrap(decoded.data.first)
        XCTAssertEqual(bucket.startTime, 1_714_003_200)

        let result = try XCTUnwrap(bucket.results.first)
        let amount = try XCTUnwrap(result.amount)
        XCTAssertEqual(try XCTUnwrap(amount.value), 1.2345)
        XCTAssertEqual(try XCTUnwrap(amount.currency), "usd")
    }

    /// Verifies multiple OpenAI cost buckets decode in order.
    func testCostsMultiDayDecodesAllBuckets() throws {
        let decoded = try FixtureLoader.decode(OpenAICostsResponse.self, from: "OpenAI/costs_multi_day")

        XCTAssertEqual(decoded.data.count, 3)

        let values = try decoded.data.map { bucket in
            let result = try XCTUnwrap(bucket.results.first)
            let amount = try XCTUnwrap(result.amount)
            return try XCTUnwrap(amount.value)
        }
        XCTAssertEqual(values, [1.2345, 2.50, 0.75])
    }

    /// Verifies an empty OpenAI costs page decodes without synthetic data.
    func testCostsEmptyDecodesToEmptyData() throws {
        let decoded = try FixtureLoader.decode(OpenAICostsResponse.self, from: "OpenAI/costs_empty")

        XCTAssertTrue(decoded.data.isEmpty)
    }

    /// Verifies pagination metadata is tolerated while bucket fields still decode.
    func testCostsPaginatedDecodesIgnoringExtraFields() throws {
        let decoded = try FixtureLoader.decode(OpenAICostsResponse.self, from: "OpenAI/costs_paginated")

        XCTAssertEqual(decoded.data.count, 1)

        let bucket = try XCTUnwrap(decoded.data.first)
        XCTAssertEqual(bucket.startTime, 1_714_262_400)

        let result = try XCTUnwrap(bucket.results.first)
        let amount = try XCTUnwrap(result.amount)
        XCTAssertEqual(try XCTUnwrap(amount.value), 3.75)
        XCTAssertEqual(try XCTUnwrap(amount.currency), "usd")
    }
}
