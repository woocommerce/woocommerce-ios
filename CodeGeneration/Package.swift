// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Codegen",
    products: [
        .library(
            name: "Codegen",
            type: .dynamic,
            targets: ["Codegen"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Codegen",
            dependencies: []),
        .testTarget(
            name: "CodegenTests",
            dependencies: ["Codegen"]),
    ]
)
