// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TestKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "TestKit",
            targets: ["TestKit"]),
    ],
    dependencies: [
        .package(name: "Difference", url: "https://github.com/krzysztofzablocki/Difference.git", .branch("master")),
        .package(url:  "https://github.com/Quick/Nimble.git", from: "13.0.0")
    ],
    targets: [
        .target(
            name: "TestKit",
            dependencies: ["Difference", "Nimble"]),
        .testTarget(
            name: "TestKitTests",
            dependencies: ["TestKit"]),
    ]
)
