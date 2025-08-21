// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tuzuru",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "tuzuru", targets: ["Command"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache.git", from: "2.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Command",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "TuzuruLib",
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .target(
            name: "TuzuruLib",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Mustache", package: "swift-mustache"),
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),
        .testTarget(name: "TuzuruLibTests"),
    ]
)
