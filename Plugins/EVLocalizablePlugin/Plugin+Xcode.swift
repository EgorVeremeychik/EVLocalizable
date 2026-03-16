#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
import PackagePlugin

extension EVLocalizablePlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let tool = try context.tool(named: "EVLocalizableGenerator")
        let outputDirectory = context.pluginWorkDirectory.appending(subpath: target.displayName)
        let catalogs = target.inputFiles.filter { file in
            file.type == .resource && file.path.extension == "xcstrings"
        }

        return catalogs.map { file in
            let enumName = sanitizedTypeName(from: file.path.stem)
            let outputFile = outputDirectory.appending(subpath: "\(enumName)+EVLocalizable.swift")

            return .buildCommand(
                displayName: "Generating \(enumName) from \(file.path.lastComponent)",
                executable: tool.path,
                arguments: [
                    "--input", file.path.string,
                    "--output", outputFile.string,
                    "--enum-name", enumName,
                ],
                inputFiles: [file.path],
                outputFiles: [outputFile]
            )
        }
    }
}

private func sanitizedTypeName(from fileStem: String) -> String {
    let parts = fileStem
        .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        .map(String.init)
        .filter { !$0.isEmpty }

    let candidate = parts.map {
        $0.prefix(1).uppercased() + $0.dropFirst()
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

#endif
