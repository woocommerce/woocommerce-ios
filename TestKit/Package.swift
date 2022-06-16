// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "TestKit",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "TestKit",
            targets: ["TestKit"]),
    ],
    dependencies: [
        .package(name: "Difference", url: "https://github.com/krzysztofzablocki/Difference.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "TestKit",
            dependencies: ["Difference"]),
        .testTarget(
            name: "TestKitTests",
            dependencies: ["TestKit"]),
    ]
)
