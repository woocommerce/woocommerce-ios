// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Hardware",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Hardware",
            targets: ["Hardware"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Notice we are pulling a beta tag.
        // See https://github.com/stripe/stripe-terminal-ios/issues/61 for
        // a discussion and the rationale behind this decission.
        // This should be fine wile we continue development, but if the Stripe SDK
        // does not provide official support for SPM whenever we start getting close
        // to release, we might need to migrate to CocoaPods.
        .package(name: "StripeTerminal", url: "https://github.com/stripe/stripe-terminal-ios", .exact("1.4.0-spmbeta")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Hardware",
            dependencies: ["StripeTerminal"]),
        .testTarget(
            name: "HardwareTests",
            dependencies: ["Hardware"]),
    ]
)
