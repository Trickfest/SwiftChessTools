// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ChessCoreRecipes",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "ChessCoreRecipes",
            dependencies: [
                .product(name: "ChessCore", package: "SwiftChessTools"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
