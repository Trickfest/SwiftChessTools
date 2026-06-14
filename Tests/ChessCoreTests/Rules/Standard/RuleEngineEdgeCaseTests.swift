//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Testing

@testable import ChessCore

@Test func pinnedRookCanOnlyMoveAlongPinLine() throws {
    expectLegalMoves(
        for: "e2",
        in: "k3r3/8/8/8/8/8/4R3/4K3 w - - 0 1",
        equal: "e2e3 e2e4 e2e5 e2e6 e2e7 e2e8"
    )
}

@Test func pinnedKnightCannotMoveWhenItShieldsKing() throws {
    expectLegalMoves(
        for: "e2",
        in: "4r1k1/8/8/8/8/8/4N3/4K3 w - - 0 1",
        equal: ""
    )

    expectLegalMoves(
        in: "4r1k1/8/8/8/8/8/4N3/4K3 w - - 0 1",
        include: ["e1d1", "e1d2", "e1f1", "e1f2"],
        exclude: ["e2c1", "e2c3", "e2d4", "e2f4", "e2g1", "e2g3"]
    )
}

@Test func pinnedBishopCanCapturePinningPieceAlongDiagonal() throws {
    expectLegalMoves(
        for: "d3",
        in: "7k/8/8/8/4b3/3B4/2K5/8 w - - 0 1",
        equal: "d3e4"
    )
}

@Test func singleCheckCanBeAnsweredByBlockCaptureOrKingMove() throws {
    let fen = "4r1k1/8/8/8/8/8/3B4/4K3 w - - 0 1"

    expectLegalMoves(
        in: fen,
        include: [
            "d2e3",  // Block the rook check.
            "e1d1",  // Move the king out of the file.
            "e1f1",
        ],
        exclude: [
            "d2c3",  // Does not answer the check.
            "d2h6",  // Does not block the e-file.
        ]
    )
}

@Test func doubleCheckAllowsOnlyKingMoves() throws {
    let fen = "k3r3/8/8/8/1b6/8/2N5/4K3 w - - 0 1"
    let legalMoves = legalMoveStrings(in: fen)

    #expect(!legalMoves.isEmpty)
    #expect(legalMoves.allSatisfy { $0.hasPrefix("e1") })
    #expect(legalMoves.contains("e1d1"))
    #expect(legalMoves.contains("e1f1"))
    #expect(legalMoves.contains("e1f2"))
    #expect(!legalMoves.contains("c2b4"))
}

@Test func movingShieldingPieceCannotExposeKing() throws {
    expectLegalMoves(
        in: "4r1k1/8/8/8/8/8/4R3/4K3 w - - 0 1",
        include: [
            "e2e3",
            "e2e4",
            "e2e5",
            "e2e6",
            "e2e7",
            "e2e8",
        ],
        exclude: [
            "e2d2",
            "e2f2",
            "e2a2",
            "e2h2",
        ]
    )
}

@Test func enPassantCannotExposeKingToDiscoveredCheck() throws {
    expectLegalMoves(
        in: "7k/8/8/r1pPK3/8/8/8/8 w - c6 0 1",
        include: ["d5d6"],
        exclude: ["d5c6"]
    )
}

@Test func enPassantHorizontalSkewersAreRejectedForBothColors() throws {
    expectLegalMoves(
        in: "4k3/8/8/r4pPK/8/8/8/8 w - f6 0 1",
        include: ["g5g6", "h5g6", "h5h4", "h5h6"],
        exclude: ["g5f6"]
    )

    expectLegalMoves(
        in: "8/8/8/8/R4Ppk/8/8/4K3 b - f3 0 1",
        include: ["g4g3", "h4g3", "h4h3", "h4h5"],
        exclude: ["g4f3"]
    )
}

@Test func enPassantCanEvadePawnCheckForBothColors() throws {
    expectLegalMoves(
        in: "4k3/8/8/3pP3/4K3/8/8/8 w - d6 0 1",
        include: ["e5d6"],
        exclude: ["e5e6"]
    )

    expectLegalMoves(
        in: "8/8/8/4k3/3Pp3/8/8/4K3 b - d3 0 1",
        include: ["e4d3"],
        exclude: ["e4e3"]
    )
}

@Test func enPassantTargetWithoutAdjacentCapturingPawnDoesNotCreateCapture() throws {
    let legalMoves = legalMoveStrings(in: "7k/8/8/3p4/8/8/4P3/4K3 w - d6 0 1")

    #expect(!legalMoves.contains { $0.hasSuffix("d6") })
    #expect(legalMoves.contains("e2e3"))
    #expect(legalMoves.contains("e2e4"))
}

@Test func castlingRequiresRightsRookPresenceSafePathAndSafeDestination() throws {
    expectLegalMoves(
        in: "4k3/8/8/8/8/8/8/4K3 w KQ - 0 1",
        exclude: ["e1g1", "e1c1"]
    )

    expectLegalMoves(
        in: "4k3/8/8/2b5/8/8/8/R3K2R w KQ - 0 1",
        include: ["e1c1"],
        exclude: ["e1g1"]
    )

    expectLegalMoves(
        in: "4k3/8/8/8/8/5b2/8/R3K2R w KQ - 0 1",
        include: ["e1g1"],
        exclude: ["e1c1"]
    )

    expectLegalMoves(
        in: "4k3/8/8/8/8/8/8/R3K2R w - - 0 1",
        exclude: ["e1g1", "e1c1"]
    )

    expectLegalMoves(
        in: "4k3/8/8/8/8/8/8/4K3 b kq - 0 1",
        exclude: ["e8g8", "e8c8"]
    )
}

@Test func castlingUsesKingPathSafetyNotRookPathAttackSafety() throws {
    expectLegalMoves(
        in: "4k3/8/8/8/8/8/b7/R3K3 w Q - 0 1",
        include: ["e1c1"],
        exclude: []
    )

    expectLegalMoves(
        in: "r3k3/B7/8/8/8/8/8/4K3 b q - 0 1",
        include: ["e8c8"],
        exclude: []
    )
}

@Test func queenSideCastlingRequiresAllSquaresBetweenKingAndRookToBeEmpty() throws {
    expectLegalMoves(
        in: "4k3/8/8/8/8/8/8/RB2K3 w Q - 0 1",
        exclude: ["e1c1"]
    )

    expectLegalMoves(
        in: "rn2k3/8/8/8/8/8/8/4K3 b q - 0 1",
        exclude: ["e8c8"]
    )
}

@Test func castlingRightsRequireMatchingRookColor() throws {
    expectLegalMoves(
        in: "4k3/8/8/8/8/8/r7/4K2R w KQ - 0 1",
        include: ["e1g1"],
        exclude: ["e1c1"]
    )

    expectLegalMoves(
        in: "4k2r/R7/8/8/8/8/8/4K3 b kq - 0 1",
        include: ["e8g8"],
        exclude: ["e8c8"]
    )
}

@Test func castlingIsRejectedWhileKingIsInKnightCheck() throws {
    expectLegalMoves(
        in: "4k3/8/8/8/8/5n2/8/R3K2R w KQ - 0 1",
        include: ["e1d1", "e1e2", "e1f1", "e1f2"],
        exclude: ["e1g1", "e1c1"]
    )
}

@Test func blackCastlingRejectsAttackedTransitAndDestinationSquares() throws {
    expectLegalMoves(
        in: "r3k2r/8/8/6B1/8/8/8/4K3 b kq - 0 1",
        include: ["e8g8"],
        exclude: ["e8c8"]
    )

    expectLegalMoves(
        in: "r3k2r/8/8/5B2/8/8/8/4K3 b kq - 0 1",
        include: ["e8g8"],
        exclude: ["e8c8"]
    )

    expectLegalMoves(
        in: "r3k2r/8/8/2B5/8/8/8/4K3 b kq - 0 1",
        include: ["e8c8"],
        exclude: ["e8g8"]
    )

    expectLegalMoves(
        in: "r3k2r/8/8/8/8/1B6/8/4K3 b kq - 0 1",
        include: ["e8c8"],
        exclude: ["e8g8"]
    )
}

@Test func terminalPositionsHaveNoLegalContinuations() throws {
    let checkmate = try FENSerializer().position(
        from: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    )
    let stalemate = try FENSerializer().position(
        from: "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"
    )

    let checkmateGame = Game(position: checkmate)
    let stalemateGame = Game(position: stalemate)

    #expect(checkmateGame.isCheck)
    #expect(checkmateGame.isCheckmate)
    #expect(checkmateGame.legalMoves.isEmpty)

    #expect(!stalemateGame.isCheck)
    #expect(!stalemateGame.isCheckmate)
    #expect(stalemateGame.legalMoves.isEmpty)
}

@Test func promotionMovesIncludeAllChoicesAndNoBareFinalRankMove() throws {
    expectLegalMoves(
        for: "e7",
        in: "3n4/4P3/8/8/8/8/8/4K2k w - - 0 1",
        equal: "e7d8q e7d8r e7d8b e7d8n e7e8q e7e8r e7e8b e7e8n"
    )

    expectLegalMoves(
        for: "e7",
        in: "3r3k/4P3/8/8/8/8/8/4K3 w - - 0 1",
        equal: "e7d8q e7d8r e7d8b e7d8n e7e8q e7e8r e7e8b e7e8n"
    )

    let legalMoves = legalMoveStrings(in: "3n4/4P3/8/8/8/8/8/4K2k w - - 0 1")
    #expect(!legalMoves.contains("e7d8"))
    #expect(!legalMoves.contains("e7e8"))
}

@Test func adjacentKingsAreCheckAndKingCaptureIsNeverLegal() throws {
    let adjacentKings = try FENSerializer().position(from: "8/8/8/8/3k4/4K3/8/8 w - - 0 1")
    #expect(StandardRules().isCheck(in: adjacentKings))

    expectLegalMoves(
        in: "4k3/8/8/8/8/8/4Q3/4K3 w - - 0 1",
        exclude: ["e2e8"]
    )
}

@Test func kingCannotCaptureProtectedPiece() throws {
    expectLegalMoves(
        in: "8/8/8/8/3q4/2k5/4K3/8 w - - 0 1",
        include: ["e2e1", "e2f1", "e2f3"],
        exclude: ["e2d3", "e2d4", "e2e3"]
    )
}

@Test func stalemateHasNoLegalMovesAndIsNotCheckmate() throws {
    let position = try FENSerializer().position(from: "8/8/8/8/8/6k1/5q2/7K w - - 0 1")
    let game = Game(position: position)

    #expect(!game.isCheck)
    #expect(!game.isCheckmate)
    #expect(game.legalMoves.isEmpty)
}

private func expectLegalMoves(for coordinate: String, in fen: String, equal expected: String) {
    let position = try! FENSerializer().position(from: fen)
    let square = Square(coordinate: coordinate)
    let actual = StandardRules().legalMovesForPiece(at: square, in: position)
        .map(\.description)
        .sorted()

    #expect(actual == expected.split(separator: " ").map(String.init).sorted(), "Position: \(fen)")
}

private func expectLegalMoves(
    in fen: String,
    include expectedMoves: [String] = [],
    exclude rejectedMoves: [String] = []
) {
    let legalMoves = legalMoveStrings(in: fen)

    for move in expectedMoves {
        #expect(legalMoves.contains(move), "Expected \(move) in \(fen)")
    }

    for move in rejectedMoves {
        #expect(!legalMoves.contains(move), "Rejected \(move) in \(fen)")
    }
}

private func legalMoveStrings(in fen: String) -> [String] {
    let position = try! FENSerializer().position(from: fen)
    return StandardRules().legalMoves(in: position).map(\.description).sorted()
}
