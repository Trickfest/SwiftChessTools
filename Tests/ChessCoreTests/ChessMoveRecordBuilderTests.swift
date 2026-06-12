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

import ChessCore

private let moveRecordStartingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

@Test func moveRecordBuilderFormatsMainlineMoves() throws {
    let records = try records(
        from: moveRecordStartingFEN,
        moves: ["e2e4", "e7e5", "g1f3", "b8c6"]
    )

    #expect(records.map(\.ply) == [1, 2, 3, 4])
    #expect(records.map(\.fullMoveNumber) == [1, 1, 2, 2])
    #expect(records.map(\.side) == [.white, .black, .white, .black])
    #expect(records.map(\.san) == ["e4", "e5", "Nf3", "Nc6"])
    #expect(records.map(\.move.description) == ["e2e4", "e7e5", "g1f3", "b8c6"])
}

@Test func moveRecordBuilderFormatsSingleMoveWithoutMutatingGame() throws {
    let position = try FENSerializer().position(from: moveRecordStartingFEN)
    let game = Game(position: position)
    let move = try Move(string: "e2e4")

    let record = try ChessMoveRecordBuilder().record(for: move, in: game, ply: 7)

    #expect(record == ChessMoveRecord(
        ply: 7,
        fullMoveNumber: 1,
        side: .white,
        move: move,
        san: "e4"
    ))
    #expect(game.moveHistory.isEmpty)
}

@Test func moveRecordBuilderHandlesOddHalfMoveCounts() throws {
    let records = try records(
        from: moveRecordStartingFEN,
        moves: ["e2e4", "e7e5", "g1f3"]
    )

    #expect(records.count == 3)
    #expect(records.last?.fullMoveNumber == 2)
    #expect(records.last?.side == .white)
    #expect(records.last?.san == "Nf3")
}

@Test func moveRecordBuilderHandlesBlackToMoveStartingPositions() throws {
    let records = try records(
        from: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
        moves: ["c7c5", "g1f3"]
    )

    #expect(records.map(\.fullMoveNumber) == [1, 2])
    #expect(records.map(\.side) == [.black, .white])
    #expect(records.map(\.san) == ["c5", "Nf3"])
}

@Test func moveRecordBuilderFormatsCastlingPromotionAndCheckmate() throws {
    let castling = try records(
        from: "r2q1rk1/ppp1bppp/2np1n2/4p3/2BPP1b1/2N1BN2/PPP1QPPP/R3K2R w KQ - 8 8",
        moves: ["e1g1"]
    )
    let promotion = try records(
        from: "8/P4pk1/6p1/6Pp/3b3P/8/8/4K3 w - - 0 1",
        moves: ["a7a8q"]
    )
    let mate = try records(
        from: "r3k3/pb3p2/1pp4p/3p4/N2P2r1/1P1BP1q1/P5Q1/1RR3K1 b q - 1 26",
        moves: ["g3g2"]
    )

    #expect(castling.first?.san == "O-O")
    #expect(promotion.first?.san == "a8=Q")
    #expect(mate.first?.san == "Qxg2#")
}

@Test func moveRecordBuilderRejectsIllegalMoves() throws {
    let builder = ChessMoveRecordBuilder()
    let initialPosition = try FENSerializer().position(from: moveRecordStartingFEN)
    let illegalMove = try Move(string: "e2e5")

    do {
        _ = try builder.records(initialPosition: initialPosition, moves: [illegalMove])
        Issue.record("Expected illegal move to fail")
    } catch let error as ChessMoveRecordBuilderError {
        #expect(error == .illegalMove(move: illegalMove, ply: 1))
    } catch {
        Issue.record("Expected ChessMoveRecordBuilderError, got: \(error)")
    }
}

private func records(from fen: String, moves coordinateMoves: [String]) throws -> [ChessMoveRecord] {
    try ChessMoveRecordBuilder().records(
        initialPosition: FENSerializer().position(from: fen),
        moves: coordinateMoves.map { try Move(string: $0) }
    )
}
