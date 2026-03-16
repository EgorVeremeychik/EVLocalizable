import Foundation
import PackagePlugin

@main
struct EVLocalizablePlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let tool = try context.tool(named: "EVLocalizableGenerator")
        let outputDirectory = context.pluginWorkDirectory.appending(subpath: target.name)

        return [
            .prebuildCommand(
                displayName: "Generating localizable enums for \(target.name)",
                executable: tool.path,
                arguments: [
                    "--search-path", target.directory.string,
                    "--output-dir", outputDirectory.string,
                ],
                outputFilesDirectory: outputDirectory
            )
        ]
    }
}
