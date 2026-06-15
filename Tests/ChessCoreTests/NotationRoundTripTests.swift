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
    "Generated legal FEN round trips",
    arguments: Array(0..<20)
)
func generatedLegalPositionsRoundTripThroughFEN(seed: Int) throws {
    let fenSerializer = FENSerializer()
    let game = Game(position: try fenSerializer.position(from: PGNSerializer.standardStartingFEN))
    var generator = NotationDeterministicGenerator(seed: UInt64(seed + 10_000))

    for ply in 0..<80 {
        let fen = fenSerializer.fen(from: game.position)
        let reparsed = try fenSerializer.position(from: fen)
        #expect(reparsed == game.position, "Seed \(seed), ply \(ply), FEN \(fen)")

        let legalMoves = game.legalMoves.sorted { $0.description < $1.description }
        guard !legalMoves.isEmpty else {
            return
        }
        game.apply(move: legalMoves[generator.nextIndex(upperBound: legalMoves.count)])
    }
}

@Test(
    "Generated legal SAN round trips",
    arguments: Array(0..<20)
)
func generatedLegalMovesRoundTripThroughSAN(seed: Int) throws {
    let sanSerializer = SANSerializer()
    let game = Game(position: try FENSerializer().position(from: PGNSerializer.standardStartingFEN))
    var generator = NotationDeterministicGenerator(seed: UInt64(seed + 20_000))

    for ply in 0..<80 {
        let legalMoves = game.legalMoves.sorted { $0.description < $1.description }
        guard !legalMoves.isEmpty else {
            return
        }

        let move = legalMoves[generator.nextIndex(upperBound: legalMoves.count)]
        let san = sanSerializer.san(for: move, in: game)
        let reparsedMove = try sanSerializer.move(for: san, in: game)
        #expect(reparsedMove == move, "Seed \(seed), ply \(ply), SAN \(san)")
        game.apply(move: move)
    }
}

@Test(
    "Generated legal game status invariants",
    arguments: Array(0..<20)
)
func generatedLegalGameStatusInvariantsStayCoherent(seed: Int) throws {
    let game = Game(position: try FENSerializer().position(from: PGNSerializer.standardStartingFEN))
    var generator = NotationDeterministicGenerator(seed: UInt64(seed + 30_000))

    for ply in 0..<100 {
        let legalMoves = game.legalMoves.sorted { $0.description < $1.description }

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
            return
        case let .draw(reason):
            #expect(game.outcome == .draw, "Seed \(seed), ply \(ply)")
            switch reason {
            case .stalemate:
                #expect(legalMoves.isEmpty, "Seed \(seed), ply \(ply)")
                #expect(!game.isCheck, "Seed \(seed), ply \(ply)")
            case .insufficientMaterial:
                #expect(game.drawClaims.isEmpty, "Seed \(seed), ply \(ply)")
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
            return
        }

        game.apply(move: legalMoves[generator.nextIndex(upperBound: legalMoves.count)])
    }
}

private struct NotationDeterministicGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9e37_79b9_7f4a_7c15
    }

    mutating func nextIndex(upperBound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(state % UInt64(upperBound))
    }
}
