// swift-tools-version:6.0
import PackageDescription

// `build-settings-police` lives in its own SwiftPM package — separate from
// `BuildTools/` — because it depends on `XcodeProj` 9.x while Sourcery 2.3.0
// (in `BuildTools/`) exact-pins `XcodeProj` 8.24.6 and is not yet on Swift 6,
// so the two graphs cannot be resolved together.
//
// Track https://github.com/krzysztofzablocki/Sourcery/issues/1457 — once a new
// Sourcery release lands with a loosened `XcodeProj` constraint, this package
// can be folded back into `BuildTools/`.
let package = Package(
    name: "BuildSettingsPolice",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/Automattic/xcode-build-settings-police.git", revision: "872287e2e01daf6d3574acf9a41c19ec4e0e6529")
    ],
    targets: [.target(name: "BuildSettingsPoliceRunner", path: "")]
)
