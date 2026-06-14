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

private struct PerftCase: Sendable {
    var name: String
    var fen: String
    var expectedNodeCounts: [Int: Int]
}

private let perftCases: [PerftCase] = [
    PerftCase(
        name: "Starting position",
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        expectedNodeCounts: [1: 20, 2: 400, 3: 8_902, 4: 197_281]
    ),
    PerftCase(
        name: "Kiwipete",
        fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
        expectedNodeCounts: [1: 48, 2: 2_039, 3: 97_862]
    ),
    PerftCase(
        name: "En passant and checks",
        fen: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
        expectedNodeCounts: [1: 14, 2: 191, 3: 2_812, 4: 43_238]
    ),
    PerftCase(
        name: "Promotions and castling",
        fen: "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
        expectedNodeCounts: [1: 6, 2: 264, 3: 9_467]
    ),
    PerftCase(
        name: "Promotion race",
        fen: "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
        expectedNodeCounts: [1: 44, 2: 1_486, 3: 62_379]
    ),
    PerftCase(
        name: "Middle game pressure",
        fen: "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
        expectedNodeCounts: [1: 46, 2: 2_079, 3: 89_890]
    ),
    PerftCase(
        name: "Bare kings in opposite corners",
        fen: "8/8/8/8/8/8/8/K6k w - - 0 1",
        expectedNodeCounts: [1: 3, 2: 9]
    ),
    PerftCase(
        name: "Opposed kings restrict movement",
        fen: "8/8/8/8/8/4K3/8/4k3 w - - 0 1",
        expectedNodeCounts: [1: 5]
    ),
    PerftCase(
        name: "Stalemate has no legal continuations",
        fen: "8/8/8/8/8/6k1/5q2/7K w - - 0 1",
        expectedNodeCounts: [1: 0]
    ),
    PerftCase(
        name: "Lone kings separated in center files",
        fen: "8/8/8/8/4K3/8/8/4k3 w - - 0 1",
        expectedNodeCounts: [1: 8]
    ),
    PerftCase(
        name: "Queen-side castling requires rook and adds one king move",
        fen: "4k3/8/8/8/8/8/8/R3K3 w Q - 0 1",
        expectedNodeCounts: [1: 16]
    ),
    PerftCase(
        name: "Castling rights without rooks do not add moves",
        fen: "4k3/8/8/8/8/8/8/4K3 w KQ - 0 1",
        expectedNodeCounts: [1: 5]
    ),
    PerftCase(
        name: "White promotion choices are generated",
        fen: "4k3/P7/8/8/8/8/8/4K3 w - - 0 1",
        expectedNodeCounts: [1: 9]
    ),
    PerftCase(
        name: "Black promotion choices are generated",
        fen: "4k3/8/8/8/8/8/p7/4K3 b - - 0 1",
        expectedNodeCounts: [1: 9]
    ),
    PerftCase(
        name: "Legal en passant adds one pawn capture",
        fen: "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1",
        expectedNodeCounts: [1: 7]
    ),
    PerftCase(
        name: "White en passant horizontal skewer rejects capture",
        fen: "4k3/8/8/r4pPK/8/8/8/8 w - f6 0 1",
        expectedNodeCounts: [1: 4, 2: 66, 3: 289]
    ),
    PerftCase(
        name: "Black en passant horizontal skewer rejects capture",
        fen: "8/8/8/8/R4Ppk/8/8/4K3 b - f3 0 1",
        expectedNodeCounts: [1: 4, 2: 66, 3: 289]
    ),
    PerftCase(
        name: "White en passant can evade pawn check",
        fen: "4k3/8/8/3pP3/4K3/8/8/8 w - d6 0 1",
        expectedNodeCounts: [1: 8, 2: 44, 3: 316]
    ),
    PerftCase(
        name: "Black en passant can evade pawn check",
        fen: "8/8/8/4k3/3Pp3/8/8/4K3 b - d3 0 1",
        expectedNodeCounts: [1: 8, 2: 44, 3: 316]
    ),
    PerftCase(
        name: "White queen-side castling ignores attack on b1",
        fen: "4k3/8/8/8/8/8/b7/R3K3 w Q - 0 1",
        expectedNodeCounts: [1: 10, 2: 109, 3: 1_631]
    ),
    PerftCase(
        name: "Black queen-side castling ignores attack on b8",
        fen: "r3k3/B7/8/8/8/8/8/4K3 b q - 0 1",
        expectedNodeCounts: [1: 10, 2: 109, 3: 1_631]
    ),
    PerftCase(
        name: "White queen-side castling requires b1 to be empty",
        fen: "4k3/8/8/8/8/8/8/RB2K3 w Q - 0 1",
        expectedNodeCounts: [1: 19, 2: 87]
    ),
    PerftCase(
        name: "Black queen-side castling requires b8 to be empty",
        fen: "rn2k3/8/8/8/8/8/8/4K3 b q - 0 1",
        expectedNodeCounts: [1: 15, 2: 70]
    ),
    PerftCase(
        name: "Castling rejected while king is in knight check",
        fen: "4k3/8/8/8/8/5n2/8/R3K2R w KQ - 0 1",
        expectedNodeCounts: [1: 4, 2: 52, 3: 1_296]
    ),
    PerftCase(
        name: "Promotion captures include all choices",
        fen: "3r3k/4P3/8/8/8/8/8/4K3 w - - 0 1",
        expectedNodeCounts: [1: 11, 2: 91, 3: 933]
    ),
    PerftCase(
        name: "Fool's mate has no legal continuations",
        fen: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3",
        expectedNodeCounts: [1: 0]
    ),
    PerftCase(
        name: "Corner queen stalemate has no legal continuations",
        fen: "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1",
        expectedNodeCounts: [1: 0]
    ),
]

@Test("Known perft node counts", arguments: perftCases)
private func knownPerftNodeCounts(testCase: PerftCase) {
    let position = try! FENSerializer().position(from: testCase.fen)

    for depth in testCase.expectedNodeCounts.keys.sorted() {
        let actual = perft(position: position, depth: depth)
        #expect(
            actual == testCase.expectedNodeCounts[depth],
            "\(testCase.name) depth \(depth)"
        )
    }
}

private func perft(position: Position, depth: Int) -> Int {
    if depth == 0 {
        return 1
    }

    let game = Game(position: position)
    if depth == 1 {
        return game.legalMoves.count
    }

    return game.legalMoves.reduce(0) { total, move in
        let child = Game(position: position)
        child.apply(move: move)
        return total + perft(position: child.position, depth: depth - 1)
    }
}
