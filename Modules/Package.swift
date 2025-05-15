// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v16) // Keep in sync with Common.xcconfig
    ],
    products: [
        .library(
            name: "Modules",
            targets: ["Modules"]
        ),
        .library(
            name: "TestKit",
            targets: ["TestKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", branch: "master"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
    ],
    targets: [
        .target(name: "Modules"),
        .testTarget(
            name: "ModulesTests",
            dependencies: [.target(name: "Modules")]
        ),
        .target(
            name: "TestKit",
            dependencies: ["Difference", "Nimble"]
        ),
    ]
)
