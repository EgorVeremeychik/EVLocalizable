import EVLocalizableCore
import Foundation

struct GeneratorCommand {
    let searchPath: String
    let outputDirectory: String
    let accessLevel: String
}

enum CommandError: LocalizedError {
    case missingValue(flag: String)
    case missingRequiredFlag(String)
    case invalidAccessLevel(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let flag):
            return "Missing value for \(flag)"
        case .missingRequiredFlag(let flag):
            return "Missing required flag \(flag)"
        case .invalidAccessLevel(let value):
            return "Unsupported access level: \(value). Use 'internal' or 'public'."
        }
    }
}

@main
struct EVLocalizableGeneratorMain {
    static func main() throws {
        do {
            let command = try parse(arguments: Array(CommandLine.arguments.dropFirst()))
            let searchURL = URL(fileURLWithPath: command.searchPath)
            let outputDirectoryURL = URL(fileURLWithPath: command.outputDirectory)

            try FileManager.default.createDirectory(
                at: outputDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let descriptors = try StringCatalogDiscovery.discover(in: searchURL)

            for descriptor in descriptors {
                let catalog = try StringCatalogParser.parse(contentsOf: descriptor.inputURL)
                let source = SwiftEnumGenerator().generate(
                    catalog: catalog,
                    configuration: .init(enumName: descriptor.enumName, accessLevel: command.accessLevel)
                )

                let outputURL = outputDirectoryURL.appendingPathComponent(descriptor.outputFileName)
                try source.write(to: outputURL, atomically: true, encoding: .utf8)
            }
        } catch {
            FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func parse(arguments: [String]) throws -> GeneratorCommand {
        var values: [String: String] = [:]
        var iterator = arguments.makeIterator()

        while let argument = iterator.next() {
            guard argument.hasPrefix("--") else { continue }
            guard let value = iterator.next() else {
                throw CommandError.missingValue(flag: argument)
            }
            values[argument] = value
        }

        guard let searchPath = values["--search-path"] else {
            throw CommandError.missingRequiredFlag("--search-path")
        }
        guard let outputDirectory = values["--output-dir"] else {
            throw CommandError.missingRequiredFlag("--output-dir")
        }
        let accessLevel = values["--access-level"] ?? "internal"

        guard ["internal", "public"].contains(accessLevel) else {
            throw CommandError.invalidAccessLevel(accessLevel)
        }

        return GeneratorCommand(
            searchPath: searchPath,
            outputDirectory: outputDirectory,
            accessLevel: accessLevel
        )
    }
}
