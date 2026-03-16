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
    }

    func testGeneratesSwiftEnumFromKeys() {
        let source = SwiftEnumGenerator().generate(
            catalog: .init(keys: ["auth.login.title", "class", "9.patch"]),
            configuration: .init(enumName: "AppStrings", accessLevel: "public")
        )

        XCTAssertTrue(source.contains("public enum AppStrings"))
        XCTAssertTrue(source.contains("case authLoginTitle = \"auth.login.title\""))
        XCTAssertTrue(source.contains("case `class` = \"class\""))
        XCTAssertTrue(source.contains("case _9Patch = \"9.patch\""))
        XCTAssertTrue(source.contains("public var localized: String"))
    }

    func testDisambiguatesCollidingCaseNames() {
        let source = SwiftEnumGenerator().generate(
            catalog: .init(keys: ["user-id", "user_id"])
        )

        XCTAssertTrue(source.contains("case userId = \"user-id\""))
        XCTAssertTrue(source.contains("case userId2 = \"user_id\""))
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
}
