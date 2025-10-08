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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache.git", from: "2.0.1"),
        // Windows support requires this fix https://github.com/swiftlang/swift-markdown/pull/245 or 0.6.0
        .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.6.0"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.0"),
        .package(url: "https://github.com/ainame/swift-displaywidth.git", from: "0.0.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Command",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "DisplayWidth", package: "swift-displaywidth"),
                "TuzuruLib",
                "ToyHttpServer",
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
                .copy("Resources/templates"),
                .copy("Resources/assets"),
            ],
        ),
        .target(
            name: "ToyHttpServer"
        ),
        .testTarget(
            name: "TuzuruLibTests",
            dependencies: [
                "TuzuruLib",
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            resources: [
                .copy("Fixtures"),
            ],
        ),
    ],
)
