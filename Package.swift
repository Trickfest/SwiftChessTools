// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftChessTools",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ChessCore",
            targets: ["ChessCore"]
        ),
        .library(
            name: "ChessUI",
            targets: ["ChessUI"]
        ),
    ],
    targets: [
        .target(
            name: "ChessCore"
        ),
        .target(
            name: "ChessUI",
            dependencies: ["ChessCore"],
            resources: [
                .process("Assets/Pieces/uscf"),
            ]
        ),
        .testTarget(
            name: "ChessCoreTests",
            dependencies: ["ChessCore"]
        ),
        .testTarget(
            name: "ChessUITests",
            dependencies: ["ChessCore", "ChessUI"]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
