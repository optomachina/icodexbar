import Foundation
import XCTest

/// Marker type used to resolve the active XCTest bundle at runtime.
final class FixtureLoaderProbe {}

/// Loads JSON fixtures from the current test bundle.
enum FixtureLoader {
    enum Error: Swift.Error {
        case missing(String)
    }

    /// Returns fixture data for a provider-relative path without an extension.
    /// Defaults to `.json`; pass `ext: "jsonl"` (etc.) for other formats.
    static func loadData(
        _ path: String,
        ext: String = "json",
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Data {
        let bundle = Bundle(for: FixtureLoaderProbe.self)
        let components = path.split(separator: "/")
        guard let lastComponent = components.last else {
            XCTFail("Fixture path must not be empty", file: file, line: line)
            throw Error.missing(path)
        }
        let name = String(lastComponent)
        let subdir = components.dropLast().joined(separator: "/")
        guard let url = bundle.url(
            forResource: name,
            withExtension: ext,
            subdirectory: subdir.isEmpty ? nil : subdir
        ) else {
            XCTFail("Missing fixture: \(path).\(ext)", file: file, line: line)
            throw Error.missing(path)
        }
        return try Data(contentsOf: url)
    }

    /// Decodes a JSON fixture into the requested model type.
    static func decode<T: Decodable>(
        _ type: T.Type,
        from path: String,
        decoder: JSONDecoder = JSONDecoder(),
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T {
        try decoder.decode(type, from: loadData(path, file: file, line: line))
    }
}
