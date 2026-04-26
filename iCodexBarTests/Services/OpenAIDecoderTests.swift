@testable import iCodexBarCore
import XCTest

final class OpenAIDecoderTests: XCTestCase {
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

    func testCostsEmptyDecodesToEmptyData() throws {
        let decoded = try FixtureLoader.decode(OpenAICostsResponse.self, from: "OpenAI/costs_empty")

        XCTAssertTrue(decoded.data.isEmpty)
    }

    func testCostsPaginatedDecodesIgnoringExtraFields() throws {
        let decoded = try FixtureLoader.decode(OpenAICostsResponse.self, from: "OpenAI/costs_paginated")

        XCTAssertEqual(decoded.data.count, 1)
    }
}
