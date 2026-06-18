// swift-tools-version: 6.1

//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

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
        .library(
            name: "ChessUCI",
            targets: ["ChessUCI"]
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
                .process("Assets/Pieces.xcassets"),
            ]
        ),
        .target(
            name: "ChessUCI",
            dependencies: ["ChessCore"]
        ),
        .testTarget(
            name: "ChessCoreTests",
            dependencies: ["ChessCore"],
            exclude: [
                "Fixtures/PGN/README.md",
            ]
        ),
        .testTarget(
            name: "ChessUITests",
            dependencies: ["ChessCore", "ChessUI"],
            resources: [
                .process("SnapshotReferences"),
            ]
        ),
        .testTarget(
            name: "ChessUCITests",
            dependencies: ["ChessCore", "ChessUCI"]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
