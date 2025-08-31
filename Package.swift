// swift-tools-version: 6.1
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
        .package(url: "https://github.com/apple/swift-system.git", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Command",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                "TuzuruLib",
            ],
        ),
        .target(
            name: "TuzuruLib",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Mustache", package: "swift-mustache"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "Yams", package: "Yams"),
            ],
            resources: [
                .copy("Resources"),
            ],
        ),
        .testTarget(
            name: "TuzuruLibTests",
            dependencies: [
                "TuzuruLib",
                .product(name: "Markdown", package: "swift-markdown"),
            ],
        ),
    ],
)
