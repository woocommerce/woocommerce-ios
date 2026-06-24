// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "StoreDesignSystem",
    platforms: [
        // Keep in sync with the app's deployment target (Common.xcconfig / Modules).
        .iOS("18.0")
    ],
    products: [
        .library(
            name: "StoreDesignSystem",
            targets: ["StoreDesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "StoreDesignSystem"
        ),
        .testTarget(
            name: "StoreDesignSystemTests",
            dependencies: ["StoreDesignSystem"]
        )
    ]
)
