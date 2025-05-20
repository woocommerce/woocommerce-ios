// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        // Keep in sync with Common.xcconfig
        .iOS(.v16),
        .macOS(.v10_14),
        .watchOS(.v9)
    ],
    products: XcodeSupport.products + [
        .library(
            name: "Modules",
            targets: ["Modules"]
        ),
        .library(
            name: "Codegen",
            targets: ["Codegen"]
        ),
        .library(
            name: "TestKit",
            targets: ["TestKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Automattic/AutomatticAbout-swift.git", from: "1.1.5"),
        .package(url: "https://github.com/Automattic/Automattic-Tracks-iOS.git", from: "3.5.2"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(url: "https://github.com/danielgindi/Charts.git", from: "5.1.0"),
        .package(url: "https://github.com/envoy/Embassy", from: "4.1.2"),
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "1.0.0"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", branch: "master"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
    ],
    targets: XcodeSupport.targets + [
        .target(name: "Modules"),
        .testTarget(
            name: "ModulesTests",
            dependencies: [.target(name: "Modules")]
        ),
        .target(
            name: "Codegen",
            exclude: ["README.md", "Sourcery"] // Relative to sources path
        ),
        .target(
            name: "TestKit",
            dependencies: ["Difference", "Nimble"]
        ),
    ]
)

// MARK: - XcodeSupport (Xcode Targets)

// Below are dependencies for the respective Xcode targets.
//
// You can add internal or third-party dependencies to these targets or even
// source files and resources.
//
// - note: SwiftPM automatically detects which modules are shared between
//   multiple targets and decides when to use dynamic frameworks.
//
// ## Known Issues
//
// - SwiftPM copies resource bundles from a target, including dynamic
//   frameworks, into every target that depends on it. Make sure to avoid
//   including frameworks with large resources bundled into multiple targets.

enum XcodeTargetNames {
    static let experiments = "Experiments"
    static let experimentsTests = "ExperimentsTests"
    static let fakes = "Fakes"
    static let hardware = "Hardware"
    static let hardwareTests = "HardwareTests"
    static let networking = "Networking"
    static let networkingTests = "NetworkingTests"
    static let networkingWatchOS = "NetworkingWatchOS"
    static let notificationExtension = "NotificationExtension"
    static let sampleReceiptPrinter = "SampleReceiptPrinter"
    static let storage = "Storage"
    static let storageTests = "StorageTests"
    static let storeWidgetsExtension = "StoreWidgetsExtension"
    static let uiTestsFoundation = "UITestsFoundation"
    static let wooCommerce = "WooCommerce"
    static let wooCommerceScreenshots = "WooCommerceScreenshots"
    static let wooCommerceTests = "WooCommerceTests"
    static let wooCommerceUITests = "WooCommerceUITests"
    static let wooCommerceWatchApp = "Woo Watch App"
    static let wooFoundation = "WooFoundation"
    static let wooFoundationTests = "WooFoundationTests"
    static let wooFoundationWatchOS = "WooFoundationWatchOS"
    static let wordPressAuthenticator = "WordPressAuthenticator"
    static let wordPressAuthenticatorTests = "WordPressAuthenticatorTests"
    static let yosemite = "Yosemite"
    static let yosemiteTests = "YosemiteTests"
}

enum XcodeSupport {
    static var products: [Product] {
        [
            support(forXcodeTarget: XcodeTargetNames.experiments),
            support(forXcodeTarget: XcodeTargetNames.experimentsTests),
            support(forXcodeTarget: XcodeTargetNames.fakes),
            support(forXcodeTarget: XcodeTargetNames.hardware),
            support(forXcodeTarget: XcodeTargetNames.hardwareTests),
            support(forXcodeTarget: XcodeTargetNames.networking),
            support(forXcodeTarget: XcodeTargetNames.networkingTests),
            support(forXcodeTarget: XcodeTargetNames.networkingWatchOS),
            support(forXcodeTarget: XcodeTargetNames.notificationExtension),
            support(forXcodeTarget: XcodeTargetNames.sampleReceiptPrinter),
            support(forXcodeTarget: XcodeTargetNames.storage),
            support(forXcodeTarget: XcodeTargetNames.storageTests),
            support(forXcodeTarget: XcodeTargetNames.storeWidgetsExtension),
            support(forXcodeTarget: XcodeTargetNames.uiTestsFoundation),
            support(forXcodeTarget: XcodeTargetNames.wooCommerce),
            support(forXcodeTarget: XcodeTargetNames.wooCommerceScreenshots),
            support(forXcodeTarget: XcodeTargetNames.wooCommerceTests),
            support(forXcodeTarget: XcodeTargetNames.wooCommerceUITests),
            support(forXcodeTarget: XcodeTargetNames.wooCommerceWatchApp),
            support(forXcodeTarget: XcodeTargetNames.wooFoundation),
            support(forXcodeTarget: XcodeTargetNames.wooFoundationTests),
            support(forXcodeTarget: XcodeTargetNames.wooFoundationWatchOS),
            support(forXcodeTarget: XcodeTargetNames.wordPressAuthenticator),
            support(forXcodeTarget: XcodeTargetNames.wordPressAuthenticatorTests),
            support(forXcodeTarget: XcodeTargetNames.yosemite),
            support(forXcodeTarget: XcodeTargetNames.yosemiteTests)
        ]
    }

    static var targets: [Target] {
        [
            .xcodeTarget(
                XcodeTargetNames.experiments,
                dependencies: [
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.experimentsTests,
                dependencies: [
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                    XcodeTargetNames.experiments.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.fakes,
                dependencies: ["Codegen"]
            ),
            .xcodeTarget(
                XcodeTargetNames.hardware,
                dependencies: [
                    "Codegen",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.hardwareTests,
                dependencies: [XcodeTargetNames.hardware.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.networking,
                dependencies: [
                    "Codegen",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    XcodeTargetNames.wooFoundation.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.networkingTests,
                dependencies: [
                    "Codegen",
                    "TestKit",
                    XcodeTargetNames.networking.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.networkingWatchOS,
                dependencies: [
                    "Codegen",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
                ]
            ),
            .xcodeTarget(XcodeTargetNames.notificationExtension, dependencies: []),
            .xcodeTarget(
                XcodeTargetNames.sampleReceiptPrinter,
                dependencies: [XcodeTargetNames.hardware.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.storage,
                dependencies: ["Codegen", XcodeTargetNames.wooFoundation.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.storageTests,
                dependencies: ["TestKit", XcodeTargetNames.storage.asDependency]
            ),
            .xcodeTarget(XcodeTargetNames.storeWidgetsExtension, dependencies: []),
            .xcodeTarget(XcodeTargetNames.uiTestsFoundation, dependencies: []),
            .xcodeTarget(
                XcodeTargetNames.wooCommerce,
                dependencies: [
                    "Codegen",
                    .product(name: "AutomatticAbout", package: "AutomatticAbout-swift"),
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                    .product(name: "AutomatticEncryptedLogs", package: "Automattic-Tracks-iOS"),
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "ConfettiSwiftUI", package: "ConfettiSwiftUI"),
                    .product(name: "DGCharts", package: "Charts")
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceScreenshots,
                dependencies: [
                    .product(name: "Embassy", package: "Embassy"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceTests,
                dependencies: [
                    "Codegen",
                    "TestKit",
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceUITests,
                dependencies: [XcodeTargetNames.wooCommerce.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceWatchApp,
                dependencies: [
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooFoundation,
                dependencies: [
                    "Codegen",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooFoundationTests,
                dependencies: ["TestKit", XcodeTargetNames.wooFoundation.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooFoundationWatchOS,
                dependencies: [
                    "Codegen",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
                ]
            ),
            .xcodeTarget(XcodeTargetNames.wordPressAuthenticator, dependencies: []),
            .xcodeTarget(
                XcodeTargetNames.wordPressAuthenticatorTests,
                dependencies: [XcodeTargetNames.wordPressAuthenticator.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.yosemite,
                dependencies: [
                    "Codegen",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.yosemiteTests,
                dependencies: [
                    "Codegen",
                    "TestKit",
                    XcodeTargetNames.yosemite.asDependency
                ]
            )
        ]
    }
}

// Does not work, gives:
//
// > Static member 'support' cannot be used on instance of type 'Product'
//
//extension Product {
//    static func support(forXcodeTarget targetName: String) -> Product {
//        .library(
//            name: "XcodeTarget_\(targetName)",
//            targets: ["XcodeTarget_\(targetName)"]
//        )
//    }
//}
func support(forXcodeTarget targetName: String) -> Product {
    .library(
        name: targetName.supportingName,
        targets: [targetName.supportingName]
    )
}

extension Target {
    static func xcodeTarget(_ name: String, dependencies: [Dependency]) -> Target {
        .target(
            name: name.supportingName,
            dependencies: dependencies,
            path: "Sources/XcodeSupport/\(name.replacing(" ", with: "-").supportingName)"
        )
    }
}

extension String {
    var supportingName: String {
        "XcodeTarget_\(self)"
    }

    var asDependency: Target.Dependency {
        .target(name: self.supportingName)
    }
}
