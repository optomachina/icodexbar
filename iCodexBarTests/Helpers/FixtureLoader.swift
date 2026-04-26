import Foundation
import XCTest

final class FixtureLoaderProbe {}

enum FixtureLoader {
    enum Error: Swift.Error {
        case missing(String)
    }

    static func loadData(
        _ path: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Data {
        let bundle = Bundle(for: FixtureLoaderProbe.self)
        let components = path.split(separator: "/")
        let name = String(components.last!)
        let subdir = components.dropLast().joined(separator: "/")
        guard let url = bundle.url(
            forResource: name,
            withExtension: "json",
            subdirectory: subdir.isEmpty ? nil : subdir
        ) else {
            XCTFail("Missing fixture: \(path).json", file: file, line: line)
            throw Error.missing(path)
        }
        return try Data(contentsOf: url)
    }

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
