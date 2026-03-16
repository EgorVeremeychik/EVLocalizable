import Foundation

public struct StringCatalogDescriptor: Sendable, Equatable {
    public let inputURL: URL
    public let outputFileName: String
    public let enumName: String

    public init(inputURL: URL, outputFileName: String, enumName: String) {
        self.inputURL = inputURL
        self.outputFileName = outputFileName
        self.enumName = enumName
    }
}

public enum StringCatalogDiscovery {
    public static func discover(in directoryURL: URL) throws -> [StringCatalogDescriptor] {
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var descriptors: [StringCatalogDescriptor] = []

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])

            if resourceValues.isDirectory == true, shouldSkipDirectory(named: fileURL.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            guard resourceValues.isRegularFile == true, fileURL.pathExtension == "xcstrings" else {
                continue
            }

            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let enumName = SwiftName.makeTypeName(from: baseName)
            let outputFileName = "\(enumName)+EVLocalizable.swift"
            descriptors.append(.init(inputURL: fileURL, outputFileName: outputFileName, enumName: enumName))
        }

        return descriptors.sorted { $0.inputURL.path < $1.inputURL.path }
    }

    private static func shouldSkipDirectory(named name: String) -> Bool {
        [".build", ".git", ".swiftpm", "DerivedData"].contains(name)
    }
}

enum SwiftName {
    static func makeTypeName(from rawValue: String) -> String {
        let parts = rawValue
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !$0.isEmpty }

        let candidate = parts.map {
            $0.prefix(1).uppercased() + $0.dropFirst().lowercased()
        }.joined()

        let normalized = candidate.isEmpty ? "Localizable" : candidate
        let alphanumeric = normalized.unicodeScalars.map { scalar -> String in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : ""
        }.joined()

        if let first = alphanumeric.first, first.isNumber {
            return "_\(alphanumeric)"
        }

        return alphanumeric.isEmpty ? "Localizable" : alphanumeric
    }
}
