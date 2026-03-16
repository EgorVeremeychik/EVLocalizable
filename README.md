# EVLocalizable

Swift Package build tool plugin that automatically finds `*.xcstrings` files in a target and generates Swift enums for them.

## Usage

Attach the plugin to a target in your package:

```swift
.target(
    name: "AppFeature",
    plugins: [
        .plugin(name: "EVLocalizablePlugin", package: "EVLocalizable")
    ]
)
```

After that, the plugin scans the target directory recursively during build. For each `*.xcstrings` file it generates one Swift file in the plugin output directory.

Examples:

- `Localizable.xcstrings` -> `enum Localizable`
- `Feature Flags.xcstrings` -> `enum FeatureFlags`

Each generated enum contains:

- one case per key from `Localizable.xcstrings`
- `key` for direct access to the original localization key
- `localized` shortcut based on `NSLocalizedString`
