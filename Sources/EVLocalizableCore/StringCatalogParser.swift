import Foundation

public struct StringCatalog: Sendable {
    public let keys: [String]

    public init(keys: [String]) {
        self.keys = keys
    }
}

public enum StringCatalogParser {
    public static func parse(contentsOf url: URL) throws -> StringCatalog {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(XCStringCatalog.self, from: data)
        return StringCatalog(keys: decoded.strings.keys.sorted())
    }
}

private struct XCStringCatalog: Decodable {
    let strings: [String: XCStringEntry]
}

private struct XCStringEntry: Decodable {}
