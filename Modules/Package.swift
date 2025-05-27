// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        // Keep in sync with Common.xcconfig
        .iOS(.v16),
        .macOS(.v10_14),
        .watchOS(.v9),
    ],
    products: XcodeSupport.products + [
        .library(
            name: "Codegen",
            targets: ["Codegen"]
        ),
        .library(
            name: "TestKit",
            targets: ["TestKit"]
        ),
        .library(
            name: "WooFoundationLite",
            targets: ["WooFoundationLite"]
        ),
        .library(
            name: "WooFoundation",
            targets: ["WooFoundation"]
        ),
        .library(
            name: "WordPressShared",
            targets: ["WordPressShared"]
        ),
        .library(
            name: "WordPressUI",
            targets: ["WordPressUI", "WordPressUIObjC"]
        ),
        .library(
            name: "WPMediaPicker",
            targets: ["WPMediaPicker"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.2.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/Automattic/AutomatticAbout-swift.git", from: "1.1.5"),
        .package(url: "https://github.com/Automattic/Automattic-Tracks-iOS.git", from: "3.5.2"),
        .package(url: "https://github.com/Automattic/Gridicons-iOS", revision: "c904cb73e26e86463a78e1335c6f4fd54a9e9223"),
        .package(url: "https://github.com/Automattic/ScreenObject", from: "0.3.0"),
        .package(url: "https://github.com/buildkite/test-collector-swift", from: "0.3.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(url: "https://github.com/danielgindi/Charts.git", from: "5.1.0"),
        .package(url: "https://github.com/envoy/Embassy", from: "4.1.2"),
        // FIXME: This should be available via Tracks, but Tracks does not compile for watchOS
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.46.0"),
        .package(url: "https://github.com/jonreid/ViewControllerPresentationSpy", from: "7.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", branch: "master"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", revision: "1.1.1"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.0.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.6.2"),
        .package(url: "https://github.com/pavolkmet/ScrollViewSectionKit", from: "1.2.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "1.0.0"),
        .package(url: "https://github.com/squarefrog/UIDeviceIdentifier", from: "2.3.0"),
        .package(url: "https://github.com/stripe/stripe-terminal-ios", from: "4.2.0"),
        .package(url: "https://github.com/SVProgressHUD/SVProgressHUD", from: "2.2.5"),
        .package(url: "https://github.com/wordpress-mobile/AztecEditor-iOS", from: "1.20.0"),
        .package(url: "https://github.com/wordpress-mobile/NSObject-SafeExpectations", from: "0.0.6"),
        .package(url: "https://github.com/wordpress-mobile/wpxmlrpc", from: "0.10.0"),
        .package(url: "https://github.com/zendesk/support_sdk_ios", from: "9.0.0"),
    ],
    targets: XcodeSupport.targets + [
        .target(
            name: "Codegen",
            exclude: ["README.md", "Sourcery"] // Relative to sources path
        ),
        .target(
            name: "TestKit",
            dependencies: ["Difference", "Nimble"]
        ),
        .target(
            name: "WooFoundationLite",
            dependencies: [
                "Codegen",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "WooFoundation",
            dependencies: ["WooFoundationLite"]
        ),
        .target(
            name: "WordPressSharedObjC",
            resources: [.process("Resources")]
        ),
        .target(
            name: "WordPressShared",
            dependencies: [
                .target(name: "WordPressSharedObjC"),
            ],
            resources: [.process("Resources")]
        ),
        .target(name: "WordPressUIObjC"),
        .target(
            name: "WordPressUI",
            dependencies: [.target(name: "WordPressUIObjC")],
            resources: [.process("Resources")]
        ),
        .target(
            name: "WPMediaPicker",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "WooFoundationTests",
            dependencies: ["TestKit", .target(name: "WooFoundation")]
        ),
        .testTarget(
            name: "WordPressUITests",
            dependencies: [.target(name: "WordPressUI")]
        ),
        .testTarget(
            name: "WordPressSharedTests",
            dependencies: [.target(name: "WordPressShared")]
        ),
        .testTarget(
            name: "WordPressSharedObjCTests",
            dependencies: [.target(name: "WordPressShared")],
            resources: [.process("Resources")]
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
    static let wordPressAuthenticator = "WordPressAuthenticator"
    static let wordPressAuthenticatorTests = "WordPressAuthenticatorTests"
    static let yosemite = "Yosemite"
    static let yosemiteTests = "YosemiteTests"
}

enum XcodeSupport {
    static var products: [Product] {
        [
            XcodeTargetNames.experiments,
            XcodeTargetNames.experimentsTests,
            XcodeTargetNames.fakes,
            XcodeTargetNames.hardware,
            XcodeTargetNames.hardwareTests,
            XcodeTargetNames.networking,
            XcodeTargetNames.networkingTests,
            XcodeTargetNames.networkingWatchOS,
            XcodeTargetNames.notificationExtension,
            XcodeTargetNames.sampleReceiptPrinter,
            XcodeTargetNames.storage,
            XcodeTargetNames.storageTests,
            XcodeTargetNames.storeWidgetsExtension,
            XcodeTargetNames.uiTestsFoundation,
            XcodeTargetNames.wooCommerce,
            XcodeTargetNames.wooCommerceScreenshots,
            XcodeTargetNames.wooCommerceTests,
            XcodeTargetNames.wooCommerceUITests,
            XcodeTargetNames.wooCommerceWatchApp,
            XcodeTargetNames.wordPressAuthenticator,
            XcodeTargetNames.wordPressAuthenticatorTests,
            XcodeTargetNames.yosemite,
            XcodeTargetNames.yosemiteTests
        ].map { .supportingProduct(forXcodeTarget: $0) }
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
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "StripeTerminal", package: "stripe-terminal-ios")
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
                    "WooFoundation",
                    "WordPressShared",
                    .product(name: "Alamofire", package: "Alamofire"),
                    .product(name: "Aztec", package: "AztecEditor-iOS"),
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.networkingTests,
                dependencies: [
                    "Codegen",
                    "TestKit",
                    "WooFoundation",
                    "WordPressShared",
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                    XcodeTargetNames.networking.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.networkingWatchOS,
                dependencies: [
                    "Codegen",
                    .product(name: "Alamofire", package: "Alamofire"),
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.notificationExtension,
                dependencies: [
                    "WooFoundation",
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.sampleReceiptPrinter,
                dependencies: [XcodeTargetNames.hardware.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.storage,
                dependencies: ["Codegen", "WooFoundation"]
            ),
            .xcodeTarget(
                XcodeTargetNames.storageTests,
                dependencies: ["TestKit", XcodeTargetNames.storage.asDependency]
            ),
            .xcodeTarget(
                XcodeTargetNames.storeWidgetsExtension,
                dependencies: [
                    "WooFoundation",
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.uiTestsFoundation,
                dependencies: [
                    .product(name: "ScreenObject", package: "ScreenObject"),
                    .product(name: "XCUITestHelpers", package: "ScreenObject"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerce,
                dependencies: [
                    "Codegen",
                    "WooFoundation",
                    "WordPressShared",
                    "WordPressUI",
                    "WPMediaPicker",
                    .product(name: "Alamofire", package: "Alamofire"),
                    .product(name: "Algorithms", package: "swift-algorithms"),
                    .product(name: "AutomatticAbout", package: "AutomatticAbout-swift"),
                    .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                    .product(name: "AutomatticEncryptedLogs", package: "Automattic-Tracks-iOS"),
                    .product(name: "Aztec", package: "AztecEditor-iOS"),
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "ConfettiSwiftUI", package: "ConfettiSwiftUI"),
                    .product(name: "DGCharts", package: "Charts"),
                    .product(name: "Gridicons", package: "Gridicons-iOS"),
                    .product(name: "Inject", package: "Inject"),
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                    .product(name: "Kingfisher", package: "Kingfisher"),
                    .product(name: "ScrollViewSectionKit", package: "ScrollViewSectionKit"),
                    .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                    .product(name: "StripeTerminal", package: "stripe-terminal-ios"),
                    .product(name: "WordPressEditor", package: "AztecEditor-iOS"),
                    .product(name: "ZendeskSupportSDK", package: "support_sdk_ios"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceScreenshots,
                dependencies: [
                    .product(name: "Embassy", package: "Embassy"),
                    .product(name: "ScreenObject", package: "ScreenObject"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceTests,
                dependencies: [
                    "Codegen",
                    "TestKit",
                    "WordPressShared",
                    .product(name: "Aztec", package: "AztecEditor-iOS"),
                    .product(name: "BuildkiteTestCollector", package: "test-collector-swift"),
                    .product(name: "ViewControllerPresentationSpy", package: "ViewControllerPresentationSpy"),
                    .product(name: "ViewInspector", package: "ViewInspector"),
                    .product(name: "WordPressEditor", package: "AztecEditor-iOS"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceUITests,
                dependencies: [
                    .product(name: "ScreenObject", package: "ScreenObject"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceWatchApp,
                dependencies: [
                    "WooFoundationLite",
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                    .product(name: "Sentry", package: "sentry-cocoa"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wordPressAuthenticator,
                dependencies: [
                    "WordPressShared",
                    "WordPressUI",
                    .product(name: "Gridicons", package: "Gridicons-iOS"),
                    .product(name: "NSObject-SafeExpectations", package: "NSObject-SafeExpectations"),
                    .product(name: "SVProgressHUD", package: "SVProgressHUD"),
                    .product(name: "UIDeviceIdentifier", package: "UIDeviceIdentifier"),
                    .product(name: "wpxmlrpc", package: "wpxmlrpc")
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wordPressAuthenticatorTests,
                dependencies: [
                    "WordPressShared",
                    .product(name: "Alamofire", package: "Alamofire"),
                    .product(name: "OHHTTPStubs", package: "OHHTTPStubs"),
                    .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                    XcodeTargetNames.wordPressAuthenticator.asDependency,
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.yosemite,
                dependencies: [
                    "Codegen",
                    "WooFoundation",
                    "WordPressShared",
                    .product(name: "Alamofire", package: "Alamofire"),
                    .product(name: "Aztec", package: "AztecEditor-iOS"),
                    .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                    .product(name: "StripeTerminal", package: "stripe-terminal-ios"),
                    .product(name: "WordPressEditor", package: "AztecEditor-iOS"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.yosemiteTests,
                dependencies: [
                    "Codegen",
                    "TestKit",
                    "WooFoundation",
                    "WordPressShared",
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
extension Product {
    static func supportingProduct(forXcodeTarget targetName: String) -> Product {
        .library(
            name: "XcodeTarget_\(targetName)",
            targets: ["XcodeTarget_\(targetName)"]
        )
    }
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
