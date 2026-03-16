// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EVLocalizable",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
        .iOS(.v15)
    ],
    products: [
        .library(name: "EVLocalizableCore", targets: ["EVLocalizableCore"]),
        .plugin(name: "EVLocalizablePlugin", targets: ["EVLocalizablePlugin"]),
    ],
    targets: [
        .target(name: "EVLocalizableCore"),
        .executableTarget(name: "EVLocalizableGenerator", dependencies: ["EVLocalizableCore"]),
        .plugin(
            name: "EVLocalizablePlugin",
            capability: .buildTool(),
            dependencies: ["EVLocalizableGenerator"]
        ),
        .testTarget(
            name: "EVLocalizableCoreTests",
            dependencies: ["EVLocalizableCore"]
        ),
    ]
)
