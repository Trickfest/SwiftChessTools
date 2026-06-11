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

@Test func moveHistory() {
    let fenSerializer = FENSerializer()
    let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    let position = try! fenSerializer.position(from: fen)
    let game = Game(position: position)

    let moves = ["e2e4", "e7e5", "g1f3", "b8c6", "d2d4", "e5d4"]
        .map { try! Move(string: $0) }

    moves.forEach { game.apply(move: $0) }

    #expect(moves == game.moveHistory)

    #expect(
        "r1bqkbnr/pppp1ppp/2n5/8/3pP3/5N2/PPP2PPP/RNBQKB1R w KQkq - 0 4"
            == fenSerializer.fen(from: game.position)
    )
}

@Test func positionCounts() {
    let fenSerializer = FENSerializer()
    let fen = "1K2Q3/8/8/6p1/5pk1/8/7P/8 w - - 3 66"
    let position = try! fenSerializer.position(from: fen)
    let game = Game(position: position)

    #expect(game.positionCounts[game.position.board] == 1)

    try! game.apply(move: "b8a8")
    try! game.apply(move: "g4f3")
    try! game.apply(move: "a8b8")
    try! game.apply(move: "f3g4")
    #expect(game.positionCounts[game.position.board] == 2)

    try! game.apply(move: "b8a8")
    try! game.apply(move: "g4f3")
    try! game.apply(move: "a8b8")
    try! game.apply(move: "f3g4")
    #expect(game.positionCounts[game.position.board] == 3)
}

@Test func simpleMove() {
    let fenSerializer = FENSerializer()
    let initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    let position = try! fenSerializer.position(from: initialFen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    try! game.apply(move: "e2e4")
    #expect(game.position.board["e4"] == Piece(kind: .pawn, color: .white))
    #expect(game.position.board["e2"] == nil)
    #expect(game.position.state.turn == PieceColor.black)
    #expect(game.position.state.enPassant == Square(coordinate: "e3"))
    #expect(game.position.counter.fullMoves == 1)

    try! game.apply(move: "d7d5")
    #expect(game.position.state.turn == PieceColor.white)
    #expect(game.position.state.enPassant == Square(coordinate: "d6"))
    #expect(game.position.counter.fullMoves == 2)

    try! game.apply(move: "g1f3")
    #expect(game.position.state.enPassant == nil)
    #expect(game.position.counter.halfMoves == 1)
}

@Test func losesKingSideCastlingRight() {
    let fenSerializer = FENSerializer()
    let fen = "r1bqk1nr/pppp1ppp/2n5/2b5/2BpP3/5N2/PPP2PPP/RNBQK2R w KQkq - 2 5"
    let position = try! fenSerializer.position(from: fen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    #expect(game.position.state.castlingRights.contains(Piece(kind: .king, color: .white)) == true)

    try! game.apply(move: "h1g1")
    #expect(game.position.state.castlingRights.contains(Piece(kind: .king, color: .white)) == false)
}

@Test func losesQueenSideCastlingRight() {
    let fenSerializer = FENSerializer()
    let fen = "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1"
    let position = try! fenSerializer.position(from: fen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    #expect(game.position.state.castlingRights.contains(Piece(kind: .queen, color: .white)) == true)

    try! game.apply(move: "a1b1")
    #expect(game.position.state.castlingRights.contains(Piece(kind: .queen, color: .white)) == false)
}

@Test func losesAllCastlingRightsAfterKingMove() {
    let fenSerializer = FENSerializer()
    let fen = "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1"
    let position = try! fenSerializer.position(from: fen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    #expect(game.position.state.castlingRights.contains(Piece(kind: .queen, color: .white)) == true)
    #expect(game.position.state.castlingRights.contains(Piece(kind: .king, color: .white)) == true)

    try! game.apply(move: "e1e2")
    #expect(game.position.state.castlingRights.contains(Piece(kind: .queen, color: .white)) == false)
    #expect(game.position.state.castlingRights.contains(Piece(kind: .king, color: .white)) == false)
}

@Test func kingCastling() {
    let fenSerializer = FENSerializer()
    let fen = "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1"
    let position = try! fenSerializer.position(from: fen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    try! game.apply(move: "e1g1")

    #expect(game.position.board["e1"] == nil)
    #expect(game.position.board["f1"] == Piece(kind: .rook, color: .white))
    #expect(game.position.board["g1"] == Piece(kind: .king, color: .white))
    #expect(game.position.board["h1"] == nil)
}

@Test func queenCastling() {
    let fenSerializer = FENSerializer()
    let fen = "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1"
    let position = try! fenSerializer.position(from: fen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    try! game.apply(move: "e1c1")

    #expect(game.position.board["a1"] == nil)
    #expect(game.position.board["b1"] == nil)
    #expect(game.position.board["c1"] == Piece(kind: .king, color: .white))
    #expect(game.position.board["d1"] == Piece(kind: .rook, color: .white))
    #expect(game.position.board["e1"] == nil)
}

@Test func enPassantCapture() {
    let fenSerializer = FENSerializer()
    let fen = "rnbqkbnr/p1pppppp/8/6P1/1pP5/8/PP1PPP1P/RNBQKBNR b KQkq c3 0 3"
    let position = try! fenSerializer.position(from: fen)
    let rules = StandardRules()
    let game = Game(position: position, rules: rules)

    try! game.apply(move: "b4c3")
    #expect(game.position.board["b4"] == nil)
    #expect(game.position.board["c4"] == nil)
    #expect(game.position.board["c3"] == Piece(kind: .pawn, color: .black))

    try! game.apply(move: "d2c3")
    try! game.apply(move: "f7f5")
    try! game.apply(move: "g5f6")
    #expect(game.position.board["g5"] == nil)
    #expect(game.position.board["f5"] == nil)
    #expect(game.position.board["f6"] == Piece(kind: .pawn, color: .white))
}

@Test func pawnPromotion() {
    let fenSerializer = FENSerializer()
    let fen = "8/1p3ppk/4p3/3p4/1p6/1K6/6p1/8 b - - 1 48"
    let position = try! fenSerializer.position(from: fen)
    let game = Game(position: position)

    try! game.apply(move: "g2g1q")
    let finalFen = fenSerializer.fen(from: game.position)

    #expect(finalFen == "8/1p3ppk/4p3/3p4/1p6/1K6/8/6q1 w - - 0 49")
}

@Test func isCheck() {
    let fenSerializer = FENSerializer()
    let checkPosition = try! fenSerializer.position(
        from: "3k4/8/8/8/5q2/8/8/5K2 w - - 0 1")
    #expect(
        StandardRules().isCheck(in: checkPosition) == true,
        "Position: \(fenSerializer.fen(from: checkPosition))")

    let notCheckPosition = try! fenSerializer.position(
        from: "3k4/8/8/8/8/4q3/8/5K2 w - - 0 1")
    #expect(
        StandardRules().isCheck(in: notCheckPosition) == false,
        "Position: \(fenSerializer.fen(from: notCheckPosition))")
}

@Test func isCheckmate() {
    let fenSerializer = FENSerializer()
    let matePosition = try! fenSerializer.position(
        from: "3k3R/8/3K4/8/8/8/8/8 b - - 0 1")
    #expect(
        StandardRules().isCheckmate(in: matePosition) == true,
        "Position: \(fenSerializer.fen(from: matePosition))")

    let checkPosition = try! fenSerializer.position(
        from: "3k4/8/8/8/5q2/8/8/5K2 w - - 0 1")
    #expect(
        StandardRules().isCheckmate(in: checkPosition) == false,
        "Position: \(fenSerializer.fen(from: checkPosition))")

    let stalematePosition = try! fenSerializer.position(
        from: "8/8/8/8/8/6k1/5q2/7K w - - 0 1")
    #expect(
        StandardRules().isCheckmate(in: stalematePosition) == false,
        "Position: \(fenSerializer.fen(from: stalematePosition))")
}
