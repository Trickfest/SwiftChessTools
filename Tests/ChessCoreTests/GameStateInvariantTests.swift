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

@Test func quietPieceMovesIncrementMoveCounters() throws {
    let game = game(from: "4k3/8/8/8/8/8/5N2/4K3 w - - 7 42")

    try game.apply(move: "f2g4")
    #expect(game.position.counter.halfMoves == 8)
    #expect(game.position.counter.fullMoves == 42)
    #expect(game.position.state.turn == .black)

    try game.apply(move: "e8e7")
    #expect(game.position.counter.halfMoves == 9)
    #expect(game.position.counter.fullMoves == 43)
    #expect(game.position.state.turn == .white)
}

@Test func pawnMovesCapturesEnPassantAndPromotionResetHalfmoveClock() throws {
    let pawnAdvance = game(from: "4k3/8/8/8/8/8/4P3/4K3 w - - 7 42")
    try pawnAdvance.apply(move: "e2e4")
    #expect(pawnAdvance.position.counter.halfMoves == 0)

    let capture = game(from: "4k3/8/8/8/3p4/8/4N3/4K3 w - - 7 42")
    try capture.apply(move: "e2d4")
    #expect(capture.position.counter.halfMoves == 0)
    #expect(capture.position.board["d4"] == Piece(kind: .knight, color: .white))

    let enPassant = game(from: "4k3/8/8/3pP3/8/8/8/4K3 w - d6 7 42")
    try enPassant.apply(move: "e5d6")
    #expect(enPassant.position.counter.halfMoves == 0)
    #expect(enPassant.position.board["d5"] == nil)
    #expect(enPassant.position.board["d6"] == Piece(kind: .pawn, color: .white))

    let promotion = game(from: "4k3/P7/8/8/8/8/8/4K3 w - - 7 42")
    try promotion.apply(move: "a7a8q")
    #expect(promotion.position.counter.halfMoves == 0)
    #expect(promotion.position.board["a8"] == Piece(kind: .queen, color: .white))
}

@Test func enPassantTargetIsCreatedOnlyByTwoSquarePawnAdvanceAndExpiresAfterOneMove() throws {
    let game = game(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )

    try game.apply(move: "g1f3")
    #expect(game.position.state.enPassant == nil)

    try game.apply(move: "e7e5")
    #expect(game.position.state.enPassant == Square(coordinate: "e6"))

    try game.apply(move: "f3g5")
    #expect(game.position.state.enPassant == nil)

    try game.apply(move: "d7d5")
    #expect(game.position.state.enPassant == Square(coordinate: "d6"))

    try game.apply(move: "e2e3")
    #expect(game.position.state.enPassant == nil)
}

@Test func castlingRightsUpdateAfterRookCapturesAndBlackKingMoves() throws {
    let queenSideCapture = game(from: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    try queenSideCapture.apply(move: "a1a8")
    expectCastlingRights(
        queenSideCapture,
        contains: [
            Piece(kind: .king, color: .white),
            Piece(kind: .king, color: .black),
        ],
        missing: [
            Piece(kind: .queen, color: .white),
            Piece(kind: .queen, color: .black),
        ]
    )

    let kingSideCapture = game(from: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    try kingSideCapture.apply(move: "h1h8")
    expectCastlingRights(
        kingSideCapture,
        contains: [
            Piece(kind: .queen, color: .white),
            Piece(kind: .queen, color: .black),
        ],
        missing: [
            Piece(kind: .king, color: .white),
            Piece(kind: .king, color: .black),
        ]
    )

    let blackKingMove = game(from: "r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1")
    try blackKingMove.apply(move: "e8e7")
    expectCastlingRights(
        blackKingMove,
        contains: [
            Piece(kind: .queen, color: .white),
            Piece(kind: .king, color: .white),
        ],
        missing: [
            Piece(kind: .queen, color: .black),
            Piece(kind: .king, color: .black),
        ]
    )
}

@Test func promotionAppliesSelectedPieceKindColorAndCounters() throws {
    let whitePromotion = game(from: "4k3/P7/8/8/8/8/8/4K3 w - - 12 30")
    try whitePromotion.apply(move: "a7a8n")
    #expect(whitePromotion.position.board["a7"] == nil)
    #expect(whitePromotion.position.board["a8"] == Piece(kind: .knight, color: .white))
    #expect(whitePromotion.position.counter.halfMoves == 0)
    #expect(whitePromotion.position.counter.fullMoves == 30)
    #expect(whitePromotion.position.state.turn == .black)

    let blackPromotion = game(from: "4k3/8/8/8/8/8/p7/4K3 b - - 12 30")
    try blackPromotion.apply(move: "a2a1q")
    #expect(blackPromotion.position.board["a2"] == nil)
    #expect(blackPromotion.position.board["a1"] == Piece(kind: .queen, color: .black))
    #expect(blackPromotion.position.counter.halfMoves == 0)
    #expect(blackPromotion.position.counter.fullMoves == 31)
    #expect(blackPromotion.position.state.turn == .white)
}

@Test func gameCopyIsIndependentAfterMutation() throws {
    let original = game(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    try original.apply(move: "e2e4")

    let copy = original.copy()
    try copy.apply(move: "d7d5")

    #expect(original.moveHistory.map(\.description) == ["e2e4"])
    #expect(copy.moveHistory.map(\.description) == ["e2e4", "d7d5"])
    #expect(original.position.state.enPassant == Square(coordinate: "e3"))
    #expect(copy.position.state.enPassant == Square(coordinate: "d6"))
    #expect(original.position.board["d5"] == nil)
    #expect(copy.position.board["d5"] == Piece(kind: .pawn, color: .black))
}

@Test func positionCountsTrackBoardOccurrencesIndependentOfCounters() throws {
    let serializer = FENSerializer()
    let initialPosition = try serializer.position(from: "8/8/8/8/8/6k1/8/4K3 w - - 0 1")
    let game = Game(position: initialPosition)

    try game.apply(move: "e1d1")
    try game.apply(move: "g3f3")
    try game.apply(move: "d1e1")
    try game.apply(move: "f3g3")

    #expect(game.position.board == initialPosition.board)
    #expect(serializer.fen(from: game.position) != serializer.fen(from: initialPosition))
    #expect(game.positionCounts[initialPosition.board] == 2)
}

private func game(from fen: String) -> Game {
    let position = try! FENSerializer().position(from: fen)
    return Game(position: position)
}

private func expectCastlingRights(
    _ game: Game,
    contains expectedRights: [Piece],
    missing missingRights: [Piece]
) {
    for right in expectedRights {
        #expect(game.position.state.castlingRights.contains(right))
    }

    for right in missingRights {
        #expect(!game.position.state.castlingRights.contains(right))
    }
}
