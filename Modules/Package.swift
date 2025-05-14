// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Modules",
    products: [
        .library(
            name: "Modules",
            targets: ["Modules"]
        ),
    ],
    targets: [
        .target(name: "Modules"),
        .testTarget(
            name: "ModulesTests",
            dependencies: [.target(name: "Modules")]
        )
    ]
)
