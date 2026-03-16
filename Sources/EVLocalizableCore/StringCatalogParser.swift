import Foundation

public struct StringCatalog: Sendable {
    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }
}

extension StringCatalog {
    public struct Entry: Sendable, Equatable {
        public let key: String
        public let developmentValue: String?

        public init(key: String, developmentValue: String?) {
            self.key = key
            self.developmentValue = developmentValue
        }
    }

    public var keys: [String] {
        entries.map(\.key)
    }
}

public enum StringCatalogParser {
    public static func parse(contentsOf url: URL) throws -> StringCatalog {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(XCStringCatalog.self, from: data)

        let entries = decoded.strings
            .map { key, entry in
                StringCatalog.Entry(
                    key: key,
                    developmentValue: entry.developmentValue(preferredLanguage: decoded.sourceLanguage)
                )
            }
            .sorted { $0.key < $1.key }

        return StringCatalog(entries: entries)
    }
}

private struct XCStringCatalog: Decodable {
    let sourceLanguage: String?
    let strings: [String: XCStringEntry]
}

private struct XCStringEntry: Decodable {
    let localizations: [String: XCStringLocalization]?

    func developmentValue(preferredLanguage: String?) -> String? {
        if let preferredLanguage, let preferred = localizations?[preferredLanguage]?.stringUnit?.value {
            return preferred
        }

        return localizations?
            .sorted { $0.key < $1.key }
            .compactMap { $0.value.stringUnit?.value }
            .first
    }
}

private struct XCStringLocalization: Decodable {
    let stringUnit: XCStringUnit?
}

private struct XCStringUnit: Decodable {
    let value: String?
}
