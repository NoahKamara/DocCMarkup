// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocCMarkup",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "DocCMarkup",
            targets: ["DocCMarkup"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-docc-symbolkit.git", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.6"),
    ],
    targets: [
        .target(
            name: "DocCMarkup",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit"),
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .testTarget(
            name: "DocCMarkupTests",
            dependencies: [
                "DocCMarkup",
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
