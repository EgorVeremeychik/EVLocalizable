import EVLocalizableCore
import XCTest

final class SwiftEnumGeneratorTests: XCTestCase {
    func testParsesXCStringsKeys() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xcstrings")
        try """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "auth.login.title" : {
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Login"
                  }
                }
              }
            },
            "common.ok" : {
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "OK"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """.write(to: url, atomically: true, encoding: .utf8)

        let catalog = try StringCatalogParser.parse(contentsOf: url)

        XCTAssertEqual(catalog.keys, ["auth.login.title", "common.ok"])
        XCTAssertEqual(catalog.entries.first?.developmentValue, "Login")
    }

    func testGeneratesSwiftEnumFromKeys() {
        let source = SwiftEnumGenerator().generate(
            catalog: .init(entries: [
                .init(key: "auth.login.title", developmentValue: "Login"),
                .init(key: "class", developmentValue: "Class"),
                .init(key: "9.patch", developmentValue: "Patch")
            ]),
            configuration: .init(enumName: "AppStrings", accessLevel: "public")
        )

        XCTAssertTrue(source.contains("public enum AppStrings"))
        XCTAssertTrue(source.contains("static let authLoginTitleKey = \"auth.login.title\""))
        XCTAssertTrue(source.contains("static var authLoginTitle: String { tr(authLoginTitleKey) }"))
        XCTAssertTrue(source.contains("static let `class`Key = \"class\""))
        XCTAssertTrue(source.contains("static var _9Patch: String { tr(_9PatchKey) }"))
        XCTAssertTrue(source.contains("public static func tr(_ key: String) -> String"))
        XCTAssertTrue(source.contains("public static func tr(_ key: String, _ args: CVarArg...) -> String"))
    }

    func testDisambiguatesCollidingCaseNames() {
        let source = SwiftEnumGenerator().generate(
            catalog: .init(entries: [
                .init(key: "user-id", developmentValue: "User"),
                .init(key: "user_id", developmentValue: "User")
            ])
        )

        XCTAssertTrue(source.contains("static var userId: String { tr(userIdKey) }"))
        XCTAssertTrue(source.contains("static var userId2: String { tr(userId2Key) }"))
    }

    func testDiscoversXCStringsRecursively() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let nested = root.appendingPathComponent("Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let xcstringsURL = nested.appendingPathComponent("Feature Flags.xcstrings")
        try "{}".write(to: xcstringsURL, atomically: true, encoding: .utf8)

        let descriptors = try StringCatalogDiscovery.discover(in: root)

        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors.first?.inputURL.lastPathComponent, "Feature Flags.xcstrings")
        XCTAssertEqual(descriptors.first?.enumName, "FeatureFlags")
        XCTAssertEqual(descriptors.first?.outputFileName, "FeatureFlags+EVLocalizable.swift")
    }

    func testPreservesCamelCaseInCatalogName() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let xcstringsURL = root.appendingPathComponent("LocalizableSecond.xcstrings")
        try "{}".write(to: xcstringsURL, atomically: true, encoding: .utf8)

        let descriptors = try StringCatalogDiscovery.discover(in: root)

        XCTAssertEqual(descriptors.first?.enumName, "LocalizableSecond")
        XCTAssertEqual(descriptors.first?.outputFileName, "LocalizableSecond+EVLocalizable.swift")
    }

    func testGeneratesTypedFunctionForFormattedString() {
        let source = SwiftEnumGenerator().generate(
            catalog: .init(entries: [
                .init(key: "welcome.message", developmentValue: "Hello, %@. You have %d messages.")
            ]),
            configuration: .init(enumName: "L10n", accessLevel: "public")
        )

        XCTAssertTrue(source.contains("static func welcomeMessage(_ arg1: String, _ arg2: Int) -> String"))
        XCTAssertTrue(source.contains("tr(welcomeMessageKey, arg1, arg2)"))
    }
}
