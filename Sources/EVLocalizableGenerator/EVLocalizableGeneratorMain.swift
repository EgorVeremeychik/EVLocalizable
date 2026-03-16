import EVLocalizableCore
import Foundation

struct GeneratorCommand {
    let input: String?
    let output: String?
    let enumName: String?
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
            if let input = command.input, let output = command.output, let enumName = command.enumName {
                try generateSingleFile(
                    input: URL(fileURLWithPath: input),
                    output: URL(fileURLWithPath: output),
                    enumName: enumName,
                    accessLevel: command.accessLevel
                )
            } else {
                let searchURL = URL(fileURLWithPath: command.searchPath)
                let outputDirectoryURL = URL(fileURLWithPath: command.outputDirectory)

                try FileManager.default.createDirectory(
                    at: outputDirectoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                let descriptors = try StringCatalogDiscovery.discover(in: searchURL)

                for descriptor in descriptors {
                    try generateSingleFile(
                        input: descriptor.inputURL,
                        output: outputDirectoryURL.appendingPathComponent(descriptor.outputFileName),
                        enumName: descriptor.enumName,
                        accessLevel: command.accessLevel
                    )
                }
            }
        } catch {
            FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func generateSingleFile(
        input: URL,
        output: URL,
        enumName: String,
        accessLevel: String
    ) throws {
        let catalog = try StringCatalogParser.parse(contentsOf: input)
        let source = SwiftEnumGenerator().generate(
            catalog: catalog,
            configuration: .init(enumName: enumName, accessLevel: accessLevel)
        )

        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try source.write(to: output, atomically: true, encoding: .utf8)
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

        let input = values["--input"]
        let output = values["--output"]
        let enumName = values["--enum-name"]
        let searchPath = values["--search-path"] ?? ""
        let outputDirectory = values["--output-dir"] ?? ""
        let accessLevel = values["--access-level"] ?? "internal"

        guard ["internal", "public"].contains(accessLevel) else {
            throw CommandError.invalidAccessLevel(accessLevel)
        }

        let usesSingleFileMode = input != nil || output != nil || enumName != nil
        if usesSingleFileMode {
            guard input != nil else { throw CommandError.missingRequiredFlag("--input") }
            guard output != nil else { throw CommandError.missingRequiredFlag("--output") }
            guard enumName != nil else { throw CommandError.missingRequiredFlag("--enum-name") }
        } else {
            guard !searchPath.isEmpty else { throw CommandError.missingRequiredFlag("--search-path") }
            guard !outputDirectory.isEmpty else { throw CommandError.missingRequiredFlag("--output-dir") }
        }

        return GeneratorCommand(
            input: input,
            output: output,
            enumName: enumName,
            searchPath: searchPath,
            outputDirectory: outputDirectory,
            accessLevel: accessLevel
        )
    }
}
