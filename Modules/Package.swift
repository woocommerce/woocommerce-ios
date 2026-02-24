// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        // Keep in sync with Common.xcconfig
        .iOS(.v17),
        .macOS(.v10_14),
        .watchOS(.v9),
    ],
    products: XcodeSupport.products + [
        .library(
            name: "APIMocks",
            targets: ["APIMocks"]
        ),
        .library(
            name: "Codegen",
            targets: ["Codegen"]
        ),
        .library(
            name: "Fakes",
            targets: ["Fakes"]
        ),
        .library(
            name: "Experiments",
            targets: ["Experiments"]
        ),
        .library(
            name: "Hardware",
            targets: ["Hardware"]
        ),
        .library(
            name: "NetworkingCore",
            targets: ["NetworkingCore"]
        ),
        .library(
            name: "Networking",
            targets: ["Networking"]
        ),
        .library(
            name: "Storage",
            targets: ["Storage"]
        ),
        .library(
            name: "TestKit",
            targets: ["TestKit"]
        ),
        .library(
            name: "WooFoundation",
            targets: ["WooFoundation"]
        ),
        .library(
            name: "WooFoundationCore",
            targets: ["WooFoundationCore"]
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
        .library(
            name: "Yosemite",
            targets: ["Yosemite"]
        ),
        .library(
            name: "PointOfSale",
            targets: ["PointOfSale"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.2.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", exact: "1.0.4"),
        .package(url: "https://github.com/Automattic/AutomatticAbout-swift.git", from: "1.1.5"),
        .package(url: "https://github.com/Automattic/Automattic-Tracks-iOS.git", from: "3.5.2"),
        .package(url: "https://github.com/Automattic/Gridicons-iOS", revision: "c904cb73e26e86463a78e1335c6f4fd54a9e9223"),
        .package(url: "https://github.com/Automattic/ScreenObject", from: "0.3.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(url: "https://github.com/danielgindi/Charts.git", from: "5.1.0"),
        .package(url: "https://github.com/envoy/Embassy", from: "4.1.2"),
        // FIXME: This should be available via Tracks, but Tracks does not compile for watchOS
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.46.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/jonreid/ViewControllerPresentationSpy", from: "7.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", branch: "master"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", revision: "1.1.1"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.0.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.6.2"),
        .package(url: "https://github.com/pmusolino/Wormholy", from: "2.0.0"),
        .package(url: "https://github.com/pavolkmet/ScrollViewSectionKit", from: "1.2.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "1.0.0"),
        .package(url: "https://github.com/squarefrog/UIDeviceIdentifier", from: "2.3.0"),
        .package(url: "https://github.com/stripe/stripe-terminal-ios", from: "5.1.1"),
        .package(url: "https://github.com/SVProgressHUD/SVProgressHUD", from: "2.2.5"),
        .package(url: "https://github.com/wordpress-mobile/AztecEditor-iOS", revision: "d741e3cfaa74c99ef092e5fddb87d4314b63e3ed"),
        .package(url: "https://github.com/wordpress-mobile/NSObject-SafeExpectations", from: "0.0.6"),
        .package(url: "https://github.com/wordpress-mobile/wpxmlrpc", from: "0.10.0"),
        .package(url: "https://github.com/zendesk/support_sdk_ios", from: "9.0.0"),
    ],
    targets: XcodeSupport.targets + [
        .target(
            name: "APIMocks",
            resources: [.process("Resources")]
        ),
        .target(
            name: "Codegen",
            exclude: ["README.md", "Sourcery"] // Relative to sources path
        ),
        .target(
            name: "Experiments",
            dependencies: [
                "WooFoundationCore",
                .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
            ]
        ),
        .target(
            name: "Fakes",
            dependencies: [
                "Codegen",
                "Hardware",
                "Networking",
                "Yosemite"
            ]
        ),
        .target(
            name: "Hardware",
            dependencies: [
                "Codegen",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "StripeTerminal", package: "stripe-terminal-ios")
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "Networking",
            dependencies: [
                "Codegen",
                "NetworkingCore",
                "WooFoundation",
                "WordPressShared",
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Aztec", package: "AztecEditor-iOS"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ]
        ),
        .target(
            name: "NetworkingCore",
            dependencies: [
                "Codegen",
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "HTMLParser", package: "AztecEditor-iOS"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ]
        ),
        .target(
            name: "Storage",
            dependencies: [
                "Codegen",
                "WooFoundation",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            exclude: ["Model/Migrations.md"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "TestKit",
            dependencies: ["Difference", "Nimble"]
        ),
        .target(
            name: "UITestsFoundation",
            dependencies: [
                .product(name: "ScreenObject", package: "ScreenObject"),
                .product(name: "XCUITestHelpers", package: "ScreenObject"),
            ]
        ),
        .target(
            name: "WooFoundation",
            dependencies: [
                "WooFoundationCore",
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "WooFoundationCore",
            dependencies: [
                "Codegen",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "WordPressShared",
            dependencies: [
                .target(name: "WordPressSharedObjC"),
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "WordPressSharedObjC",
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
        .target(
            name: "Yosemite",
            dependencies: [
                "Codegen",
                "Hardware",
                "Networking",
                "Storage",
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
        .target(
            name: "PointOfSale",
            dependencies: [
                "Experiments",
                "WooFoundation",
                "Yosemite",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ExperimentsTests",
            dependencies: [
                "Experiments",
                .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
            ]
        ),
        .testTarget(
            name: "HardwareTests",
            dependencies: [
                "Hardware"
            ]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: [
                "Codegen",
                "Fakes",
                "Networking",
                "TestKit",
                "WooFoundation",
                "WordPressShared",
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            resources: [.process("Responses")]
        ),
        .testTarget(
            name: "StorageTests",
            dependencies: [
                "Storage",
                "TestKit"
            ],
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
        .testTarget(
            name: "YosemiteTests",
            dependencies: [
                "Codegen",
                "Fakes",
                "TestKit",
                "WooFoundation",
                "WordPressShared",
                "Yosemite"
            ],
            resources: [
                .process("Resources"),
                .process("../NetworkingTests/Responses")
            ]
        ),
        .testTarget(
            name: "PointOfSaleTests",
            dependencies: [
                .target(name: "PointOfSale"),
                "Codegen",
                "Fakes",
                "TestKit",
                "WooFoundation"
            ]
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
    static let fakes = "Fakes"
    static let notificationExtension = "NotificationExtension"
    static let notificationServiceExtension = "NotificationServiceExtension"
    static let storeWidgetsExtension = "StoreWidgetsExtension"
    static let wooCommerce = "WooCommerce"
    static let wooCommerceScreenshots = "WooCommerceScreenshots"
    static let wooCommerceTests = "WooCommerceTests"
    static let wooCommerceUITests = "WooCommerceUITests"
    static let wooCommerceWatchApp = "Woo Watch App"
    static let wordPressAuthenticator = "WordPressAuthenticator"
    static let wordPressAuthenticatorTests = "WordPressAuthenticatorTests"
}

enum XcodeSupport {
    static var products: [Product] {
        [
            XcodeTargetNames.notificationExtension,
            XcodeTargetNames.notificationServiceExtension,
            XcodeTargetNames.storeWidgetsExtension,
            XcodeTargetNames.wooCommerce,
            XcodeTargetNames.wooCommerceScreenshots,
            XcodeTargetNames.wooCommerceTests,
            XcodeTargetNames.wooCommerceUITests,
            XcodeTargetNames.wooCommerceWatchApp,
            XcodeTargetNames.wordPressAuthenticator,
            XcodeTargetNames.wordPressAuthenticatorTests,
        ].map { .supportingProduct(forXcodeTarget: $0) }
    }

    static var targets: [Target] {
        [
            .xcodeTarget(
                XcodeTargetNames.notificationExtension,
                dependencies: [
                    "NetworkingCore",
                    "WooFoundation",
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.notificationServiceExtension,
                dependencies: []
            ),
            .xcodeTarget(
                XcodeTargetNames.storeWidgetsExtension,
                dependencies: [
                    "Networking",
                    "WooFoundation",
                    .product(name: "KeychainAccess", package: "KeychainAccess"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerce,
                dependencies: [
                    "Codegen",
                    "Experiments",
                    "Hardware",
                    "Networking",
                    "Storage",
                    "WooFoundation",
                    "WordPressShared",
                    "WordPressUI",
                    "WPMediaPicker",
                    "Yosemite",
                    "PointOfSale",
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
                    .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                    .product(name: "ScrollViewSectionKit", package: "ScrollViewSectionKit"),
                    .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                    .product(name: "StripeTerminal", package: "stripe-terminal-ios"),
                    .product(name: "WordPressEditor", package: "AztecEditor-iOS"),
                    .product(name: "Wormholy", package: "Wormholy"),
                    .product(name: "ZendeskSupportSDK", package: "support_sdk_ios"),
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceScreenshots,
                dependencies: [
                    "UITestsFoundation",
                    .product(name: "Embassy", package: "Embassy"),
                    .product(name: "ScreenObject", package: "ScreenObject"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceTests,
                dependencies: [
                    "Codegen",
                    "Fakes",
                    "TestKit",
                    "WordPressShared",
                    .product(name: "Aztec", package: "AztecEditor-iOS"),
                    .product(name: "ViewControllerPresentationSpy", package: "ViewControllerPresentationSpy"),
                    .product(name: "ViewInspector", package: "ViewInspector"),
                    .product(name: "WordPressEditor", package: "AztecEditor-iOS"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceUITests,
                dependencies: [
                    "APIMocks",
                    "UITestsFoundation",
                    .product(name: "ScreenObject", package: "ScreenObject"),
                    XcodeTargetNames.wooCommerce.asDependency
                ]
            ),
            .xcodeTarget(
                XcodeTargetNames.wooCommerceWatchApp,
                dependencies: [
                    "NetworkingCore",
                    "WooFoundationCore",
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
