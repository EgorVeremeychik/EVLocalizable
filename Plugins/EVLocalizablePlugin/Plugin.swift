import Foundation
import PackagePlugin

@main
struct EVLocalizablePlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let tool = try context.tool(named: "EVLocalizableGenerator")
        return [
            .prebuildCommand(
                displayName: "Generating localizable enums for \(target.name)",
                executable: tool.path,
                arguments: [
                    "--search-path", target.directory.string,
                    "--output-dir", context.pluginWorkDirectory.appending(subpath: target.name).string,
                ],
                outputFilesDirectory: context.pluginWorkDirectory.appending(subpath: target.name)
            )
        ]
    }
}
