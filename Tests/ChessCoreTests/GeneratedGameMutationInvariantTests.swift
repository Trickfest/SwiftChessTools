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

@Test(
    "Generated legal game mutations preserve invariants",
    arguments: Array(0..<12)
)
func generatedLegalGameMutationsPreserveInvariants(seed: Int) throws {
    let fenSerializer = FENSerializer()
    let sanSerializer = SANSerializer()
    let game = Game(position: try fenSerializer.position(from: PGNSerializer.standardStartingFEN))
    var generator = GameMutationDeterministicGenerator(seed: UInt64(seed + 40_000))

    for ply in 0..<50 {
        try expectGeneratedGameInvariants(
            game,
            seed: seed,
            ply: ply,
            fenSerializer: fenSerializer,
            sanSerializer: sanSerializer
        )

        let legalMoves = game.legalMoves.sorted { $0.description < $1.description }
        guard !legalMoves.isEmpty else {
            return
        }

        let previousPosition = game.position
        let previousHistoryCount = game.moveHistory.count
        let move = legalMoves[generator.nextIndex(upperBound: legalMoves.count)]
        let movingPiece = previousPosition.board[move.from]
        let capturedPiece = previousPosition.board[move.to]
        let wasEnPassantCapture = movingPiece?.kind == .pawn
            && capturedPiece == nil
            && previousPosition.state.enPassant == move.to
            && move.from.file != move.to.file

        game.apply(move: move)

        #expect(game.moveHistory.count == previousHistoryCount + 1, "Seed \(seed), ply \(ply)")
        #expect(game.moveHistory.last == move, "Seed \(seed), ply \(ply), move \(move)")
        #expect(game.position.state.turn == previousPosition.state.turn.opposite, "Seed \(seed), ply \(ply)")

        if previousPosition.state.turn == .black {
            #expect(
                game.position.counter.fullMoves == previousPosition.counter.fullMoves + 1,
                "Seed \(seed), ply \(ply), move \(move)"
            )
        } else {
            #expect(
                game.position.counter.fullMoves == previousPosition.counter.fullMoves,
                "Seed \(seed), ply \(ply), move \(move)"
            )
        }

        if movingPiece?.kind == .pawn || capturedPiece != nil || wasEnPassantCapture {
            #expect(game.position.counter.halfMoves == 0, "Seed \(seed), ply \(ply), move \(move)")
        } else {
            #expect(
                game.position.counter.halfMoves == previousPosition.counter.halfMoves + 1,
                "Seed \(seed), ply \(ply), move \(move)"
            )
        }

        let expectedEnPassant = expectedEnPassantTarget(after: move, moving: movingPiece)
        #expect(game.position.state.enPassant == expectedEnPassant, "Seed \(seed), ply \(ply), move \(move)")
    }
}

private func expectGeneratedGameInvariants(
    _ game: Game,
    seed: Int,
    ply: Int,
    fenSerializer: FENSerializer,
    sanSerializer: SANSerializer
) throws {
    expectExactlyOneKingPerSide(in: game.position, context: "Seed \(seed), ply \(ply)")

    let legalMoves = game.legalMoves.sorted { $0.description < $1.description }
    let legalMoveStrings = legalMoves.map(\.description)
    #expect(Set(legalMoveStrings).count == legalMoveStrings.count, "Seed \(seed), ply \(ply)")

    let fen = fenSerializer.fen(from: game.position)
    let reparsedPosition = try fenSerializer.position(from: fen)
    #expect(reparsedPosition == game.position, "Seed \(seed), ply \(ply), FEN \(fen)")

    let reparsedLegalMoves = Game(position: reparsedPosition).legalMoves.map(\.description).sorted()
    #expect(reparsedLegalMoves == legalMoveStrings, "Seed \(seed), ply \(ply), FEN \(fen)")

    switch game.status {
    case let .ongoing(drawClaims):
        #expect(!legalMoves.isEmpty, "Seed \(seed), ply \(ply)")
        #expect(game.outcome == nil, "Seed \(seed), ply \(ply)")
        if drawClaims.contains(.fiftyMoveRule) {
            #expect(game.position.counter.halfMoves >= 100, "Seed \(seed), ply \(ply)")
        }
        if drawClaims.contains(.threefoldRepetition) {
            #expect(game.currentRepetitionCount >= 3, "Seed \(seed), ply \(ply)")
        }
    case let .checkmate(winner):
        #expect(legalMoves.isEmpty, "Seed \(seed), ply \(ply)")
        #expect(game.isCheck, "Seed \(seed), ply \(ply)")
        #expect(winner == game.position.state.turn.opposite, "Seed \(seed), ply \(ply)")
        #expect(game.outcome == .win(winner), "Seed \(seed), ply \(ply)")
    case let .draw(reason):
        #expect(game.outcome == .draw, "Seed \(seed), ply \(ply)")
        switch reason {
        case .stalemate:
            #expect(legalMoves.isEmpty, "Seed \(seed), ply \(ply)")
            #expect(!game.isCheck, "Seed \(seed), ply \(ply)")
        case .insufficientMaterial:
            break
        case .deadPosition:
            #expect(DeadPositionAnalyzer().isDeadPosition(game.position), "Seed \(seed), ply \(ply)")
        case .seventyFiveMoveRule:
            #expect(game.position.counter.halfMoves >= 150, "Seed \(seed), ply \(ply)")
        case .fivefoldRepetition:
            #expect(game.currentRepetitionCount >= 5, "Seed \(seed), ply \(ply)")
        case .fiftyMoveRule:
            #expect(game.claimedDraw == .fiftyMoveRule, "Seed \(seed), ply \(ply)")
        case .threefoldRepetition:
            #expect(game.claimedDraw == .threefoldRepetition, "Seed \(seed), ply \(ply)")
        }
    }

    let sanMoves = movesForSampledInvariantCheck(from: legalMoves, ply: ply, fullCheckStride: 10)
    var seenSAN: Set<String> = []
    for move in sanMoves {
        let san = sanSerializer.san(for: move, in: game)
        #expect(!san.isEmpty, "Seed \(seed), ply \(ply), move \(move)")
        #expect(seenSAN.insert(san).inserted, "Seed \(seed), ply \(ply), duplicate SAN \(san)")
        #expect(try sanSerializer.move(for: san, in: game) == move, "Seed \(seed), ply \(ply), SAN \(san)")
    }

    let continuationMoves = movesForSampledInvariantCheck(from: legalMoves, ply: ply, fullCheckStride: 20)
    for move in continuationMoves {
        let nextGame = game.copy()
        nextGame.apply(move: move)
        expectExactlyOneKingPerSide(in: nextGame.position, context: "Seed \(seed), ply \(ply), move \(move)")
        expectInactiveSideIsNotInCheck(in: nextGame.position, context: "Seed \(seed), ply \(ply), move \(move)")
    }
}

private func movesForSampledInvariantCheck(
    from legalMoves: [Move],
    ply: Int,
    fullCheckStride: Int
) -> [Move] {
    guard !legalMoves.isEmpty else {
        return []
    }

    guard ply % fullCheckStride != 0 else {
        return legalMoves
    }

    let selectedIndexes = Set([0, legalMoves.count / 2, legalMoves.count - 1])
    return legalMoves.enumerated().compactMap { index, move in
        selectedIndexes.contains(index) ? move : nil
    }
}

private func expectExactlyOneKingPerSide(in position: Position, context: String) {
    let pieces = position.board.enumeratedPieces().map(\.1)
    #expect(
        pieces.filter { $0 == Piece(kind: .king, color: .white) }.count == 1,
        "\(context): expected exactly one white king"
    )
    #expect(
        pieces.filter { $0 == Piece(kind: .king, color: .black) }.count == 1,
        "\(context): expected exactly one black king"
    )
}

private func expectInactiveSideIsNotInCheck(in position: Position, context: String) {
    var inactiveTurnPosition = position
    inactiveTurnPosition.state.turn = position.state.turn.opposite

    #expect(!StandardRules().isCheck(in: inactiveTurnPosition), "\(context): inactive king is in check")
}

private func expectedEnPassantTarget(after move: Move, moving piece: Piece?) -> Square? {
    guard piece?.kind == .pawn, abs(move.to.rank - move.from.rank) == 2 else {
        return nil
    }

    return Square(file: move.from.file, rank: (move.from.rank + move.to.rank) / 2)
}

private struct GameMutationDeterministicGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9e37_79b9_7f4a_7c15
    }

    mutating func nextIndex(upperBound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(state % UInt64(upperBound))
    }
}
