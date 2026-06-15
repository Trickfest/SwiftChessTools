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

private struct PythonChessOracleCase: Sendable {
    var name: String
    var fen: String
    var legalMoves: [String]
    var isCheck: Bool
    var isCheckmate: Bool
    var isStalemate: Bool
}

// Legal move and terminal-state expectations generated with python-chess 1.999 / chess 1.11.2.
private let pythonChessOracleCases: [PythonChessOracleCase] = [
    PythonChessOracleCase(
        name: "Starting position",
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        legalMoves: [
            "a2a3", "a2a4", "b1a3", "b1c3", "b2b3", "b2b4", "c2c3", "c2c4", "d2d3", "d2d4",
            "e2e3", "e2e4", "f2f3", "f2f4", "g1f3", "g1h3", "g2g3", "g2g4", "h2h3", "h2h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "White en-passant horizontal skewer rejects exposed king",
        fen: "4k3/8/8/r4pPK/8/8/8/8 w - f6 0 1",
        legalMoves: [
            "g5g6", "h5g6", "h5h4", "h5h6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Black en-passant horizontal skewer rejects exposed king",
        fen: "8/8/8/8/R4Ppk/8/8/4K3 b - f3 0 1",
        legalMoves: [
            "g4g3", "h4g3", "h4h3", "h4h5",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "White en-passant capture evades pawn check",
        fen: "4k3/8/8/3pP3/4K3/8/8/8 w - d6 0 1",
        legalMoves: [
            "e4d3", "e4d4", "e4d5", "e4e3", "e4f3", "e4f4", "e4f5", "e5d6",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Black en-passant capture evades pawn check",
        fen: "8/8/8/4k3/3Pp3/8/8/4K3 b - d3 0 1",
        legalMoves: [
            "e4d3", "e5d4", "e5d5", "e5d6", "e5e6", "e5f4", "e5f5", "e5f6",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Double check allows king moves only",
        fen: "k3r3/8/8/8/1b6/8/2N5/4K3 w - - 0 1",
        legalMoves: [
            "e1d1", "e1f1", "e1f2",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Pinned rook moves only along file",
        fen: "k3r3/8/8/8/8/8/4R3/4K3 w - - 0 1",
        legalMoves: [
            "e1d1", "e1d2", "e1f1", "e1f2", "e2e3", "e2e4", "e2e5", "e2e6", "e2e7", "e2e8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "White queen-side castling ignores rook path attack",
        fen: "4k3/8/8/8/8/8/b7/R3K3 w Q - 0 1",
        legalMoves: [
            "a1a2", "a1b1", "a1c1", "a1d1", "e1c1", "e1d1", "e1d2", "e1e2", "e1f1", "e1f2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Black queen-side castling ignores rook path attack",
        fen: "r3k3/B7/8/8/8/8/8/4K3 b q - 0 1",
        legalMoves: [
            "a8a7", "a8b8", "a8c8", "a8d8", "e8c8", "e8d7", "e8d8", "e8e7", "e8f7", "e8f8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Black castling rejects attacked transit square",
        fen: "r3k2r/8/8/6B1/8/8/8/4K3 b kq - 0 1",
        legalMoves: [
            "a8a1", "a8a2", "a8a3", "a8a4", "a8a5", "a8a6", "a8a7", "a8b8", "a8c8", "a8d8",
            "e8d7", "e8f7", "e8f8", "e8g8", "h8f8", "h8g8", "h8h1", "h8h2", "h8h3", "h8h4",
            "h8h5", "h8h6", "h8h7",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "White promotion captures and quiet promotions",
        fen: "3n4/4P3/8/8/8/8/8/4K2k w - - 0 1",
        legalMoves: [
            "e1d1", "e1d2", "e1e2", "e1f1", "e1f2", "e7d8b", "e7d8n", "e7d8q", "e7d8r",
            "e7e8b", "e7e8n", "e7e8q", "e7e8r",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "White promotion mate choices",
        fen: "1r2k3/2P5/4K3/8/8/8/8/8 w - - 0 1",
        legalMoves: [
            "c7b8b", "c7b8n", "c7b8q", "c7b8r", "c7c8b", "c7c8n", "c7c8q", "c7c8r", "e6d5",
            "e6d6", "e6e5", "e6f5", "e6f6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "White underpromotion knight mate position",
        fen: "Qr6/P7/8/8/8/8/8/k1K5 w - - 0 1",
        legalMoves: [
            "a7b8b", "a7b8n", "a7b8q", "a7b8r", "a8b7", "a8b8", "a8c6", "a8d5", "a8e4",
            "a8f3", "a8g2", "a8h1", "c1c2", "c1d1", "c1d2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Black underpromotion knight mate position",
        fen: "K1k5/8/8/8/8/8/p7/qR6 b - - 0 1",
        legalMoves: [
            "a1b1", "a1b2", "a1c3", "a1d4", "a1e5", "a1f6", "a1g7", "a1h8", "a2b1b",
            "a2b1n", "a2b1q", "a2b1r", "c8c7", "c8d7", "c8d8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Three queens ambiguity",
        fen: "4k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1",
        legalMoves: [
            "a1a2", "a1a3", "a1a4", "a1a5", "a1a6", "a1a7", "a1a8", "a1b2", "a1c3",
            "a1d4", "a1e5", "a1f6", "a1g7", "a1h8", "b1a2", "b1b2", "b1b3", "b1b4",
            "b1b5", "b1b6", "b1b7", "b1b8", "b1c2", "b1d3", "b1e4", "b1f5", "b1g6",
            "b1h7", "c1a3", "c1b2", "c1c2", "c1c3", "c1c4", "c1c5", "c1c6", "c1c7",
            "c1c8", "c1d1", "c1d2", "c1e3", "c1f4", "c1g5", "c1h6", "e1d1", "e1d2",
            "e1e2", "e1f1", "e1f2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Three rooks ambiguity",
        fen: "4k3/8/8/8/8/8/1R6/R1R1K3 w - - 0 1",
        legalMoves: [
            "a1a2", "a1a3", "a1a4", "a1a5", "a1a6", "a1a7", "a1a8", "a1b1", "b2a2",
            "b2b1", "b2b3", "b2b4", "b2b5", "b2b6", "b2b7", "b2b8", "b2c2", "b2d2",
            "b2e2", "b2f2", "b2g2", "b2h2", "c1b1", "c1c2", "c1c3", "c1c4", "c1c5",
            "c1c6", "c1c7", "c1c8", "c1d1", "e1d1", "e1d2", "e1e2", "e1f1", "e1f2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Three bishops ambiguity",
        fen: "4k3/8/8/8/8/B7/8/B1B1K3 w - - 0 1",
        legalMoves: [
            "a1b2", "a1c3", "a1d4", "a1e5", "a1f6", "a1g7", "a1h8", "a3b2", "a3b4",
            "a3c5", "a3d6", "a3e7", "a3f8", "c1b2", "c1d2", "c1e3", "c1f4", "c1g5",
            "c1h6", "e1d1", "e1d2", "e1e2", "e1f1", "e1f2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Three knights ambiguity",
        fen: "4k3/8/8/8/8/8/3N4/N1N1K3 w - - 0 1",
        legalMoves: [
            "a1b3", "a1c2", "c1a2", "c1b3", "c1d3", "c1e2", "d2b1", "d2b3", "d2c4",
            "d2e4", "d2f1", "d2f3", "e1d1", "e1e2", "e1f1", "e1f2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Dense promoted-material position",
        fen: "n1bqkbnr/P1P1P1P1/8/8/8/8/p1p1p1p1/N1BQKBNR w - - 0 1",
        legalMoves: [
            "a1b3", "a1c2", "c1a3", "c1b2", "c1d2", "c1e3", "c1f4", "c1g5", "c1h6",
            "c7d8b", "c7d8n", "c7d8q", "c7d8r", "d1c2", "d1d2", "d1d3", "d1d4",
            "d1d5", "d1d6", "d1d7", "d1d8", "d1e2", "e1e2", "e1f2", "e7d8b",
            "e7d8n", "e7d8q", "e7d8r", "e7f8b", "e7f8n", "e7f8q", "e7f8r", "f1e2",
            "f1g2", "g1e2", "g1f3", "g1h3", "g7f8b", "g7f8n", "g7f8q", "g7f8r",
            "g7h8b", "g7h8n", "g7h8q", "g7h8r", "h1h2", "h1h3", "h1h4", "h1h5",
            "h1h6", "h1h7", "h1h8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Stalemate terminal position",
        fen: "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1",
        legalMoves: [],
        isCheck: false,
        isCheckmate: false,
        isStalemate: true
    ),
    PythonChessOracleCase(
        name: "Fools mate terminal position",
        fen: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3",
        legalMoves: [],
        isCheck: true,
        isCheckmate: true,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 4",
        fen: "rnbqkbnr/p1ppppp1/1p5p/8/P7/5P2/1PPPP1PP/RNBQKBNR w KQkq - 0 3",
        legalMoves: [
            "a1a2", "a1a3", "a4a5", "b1a3", "b1c3", "b2b3", "b2b4", "c2c3", "c2c4",
            "d2d3", "d2d4", "e1f2", "e2e3", "e2e4", "f3f4", "g1h3", "g2g3", "g2g4",
            "h2h3", "h2h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 9",
        fen: "rn1qkbnr/pbpppp2/1p4pp/8/P1N5/4PP2/1PPP2PP/R1BQKBNR b KQkq - 1 5",
        legalMoves: [
            "a7a5", "a7a6", "b6b5", "b7a6", "b7c6", "b7c8", "b7d5", "b7e4", "b7f3",
            "b8a6", "b8c6", "c7c5", "c7c6", "d7d5", "d7d6", "d8c8", "e7e5", "e7e6",
            "f7f5", "f7f6", "f8g7", "g6g5", "g8f6", "h6h5", "h8h7",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 16",
        fen: "rn1qkbnr/2pppp2/p6p/Np4p1/P7/4PQ2/1PPP2PP/1RB1KBNR w Kkq - 0 9",
        legalMoves: [
            "a4b5", "a5b3", "a5b7", "a5c4", "a5c6", "b1a1", "b2b3", "b2b4", "c2c3",
            "c2c4", "d2d3", "d2d4", "e1d1", "e1e2", "e1f2", "e3e4", "f1b5", "f1c4",
            "f1d3", "f1e2", "f3a8", "f3b7", "f3c6", "f3d1", "f3d5", "f3e2", "f3e4",
            "f3f2", "f3f4", "f3f5", "f3f6", "f3f7", "f3g3", "f3g4", "f3h3", "f3h5",
            "g1e2", "g1h3", "g2g3", "g2g4", "h2h3", "h2h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 25",
        fen: "1n2kbn1/2pppp1r/r1N4p/6p1/p7/4P2Q/1PPP2PP/1RB1K1NR b K - 1 13",
        legalMoves: [
            "a4a3", "a6a5", "a6a7", "a6a8", "a6b6", "a6c6", "b8c6", "d7c6", "d7d5",
            "d7d6", "e7e5", "e7e6", "f7f5", "f7f6", "f8g7", "g5g4", "g8f6", "h6h5",
            "h7g7", "h7h8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 36",
        fen: "1n3bn1/2pkpp2/r1p5/6p1/p2N4/4P3/1PPP2Pr/1RB1K2R w - - 0 19",
        legalMoves: [
            "b1a1", "b2b3", "b2b4", "c2c3", "c2c4", "d2d3", "d4b3", "d4b5", "d4c6",
            "d4e2", "d4e6", "d4f3", "d4f5", "e1d1", "e1e2", "e1f1", "e1f2", "e3e4",
            "g2g3", "g2g4", "h1f1", "h1g1", "h1h2",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 49",
        fen: "6n1/2pkppb1/2n5/r5p1/p7/4P3/2PP2P1/1RB1K2R b - - 1 25",
        legalMoves: [
            "a4a3", "a5a6", "a5a7", "a5a8", "a5b5", "a5c5", "a5d5", "a5e5", "a5f5",
            "c6a7", "c6b4", "c6b8", "c6d4", "c6d8", "c6e5", "d7c8", "d7d6", "d7d8",
            "d7e6", "d7e8", "e7e5", "e7e6", "f7f5", "f7f6", "g5g4", "g7a1", "g7b2",
            "g7c3", "g7d4", "g7e5", "g7f6", "g7f8", "g7h6", "g7h8", "g8f6", "g8h6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 64",
        fen: "1n4n1/2p1Bp2/2k4r/4b1p1/p3P2R/6K1/2P3P1/1R6 w - - 1 33",
        legalMoves: [
            "g3f2", "g3f3", "g3g4", "g3h3", "h4f4",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 0, ply 81",
        fen: "1n6/2p2p2/2k2B2/8/p4K2/8/2P3P1/7R b - - 0 41",
        legalMoves: [
            "a4a3", "b8a6", "b8d7", "c6b5", "c6b6", "c6b7", "c6c5", "c6d5", "c6d6",
            "c6d7",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 4",
        fen: "rnbqkbnr/pp1ppppp/8/P7/2p5/8/1PPPPPPP/RNBQKBNR w KQkq - 0 3",
        legalMoves: [
            "a1a2", "a1a3", "a1a4", "a5a6", "b1a3", "b1c3", "b2b3", "b2b4", "c2c3",
            "d2d3", "d2d4", "e2e3", "e2e4", "f2f3", "f2f4", "g1f3", "g1h3", "g2g3",
            "g2g4", "h2h3", "h2h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 9",
        fen: "rnb1kbnr/Rp1pp1pp/8/5p2/2p5/2N5/1PPPPPPP/2BQKBNR b Kkq - 0 5",
        legalMoves: [
            "a8a7", "b7b5", "b7b6", "b8a6", "b8c6", "d7d5", "d7d6", "e7e5", "e7e6",
            "e8d8", "e8f7", "f5f4", "g7g5", "g7g6", "g8f6", "g8h6", "h7h5", "h7h6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 16",
        fen: "2b2bnr/rp1ppkpp/8/5p2/2pn1P2/2N4P/1PPPP1PR/2BQKBN1 w - - 3 9",
        legalMoves: [
            "b2b3", "b2b4", "c3a2", "c3a4", "c3b1", "c3b5", "c3d5", "c3e4", "d2d3",
            "e1f2", "e2e3", "e2e4", "g1f3", "g2g3", "g2g4", "h2h1", "h3h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 25",
        fen: "2b2bnr/rp2p1p1/2p3k1/5p1p/N4P2/3P3P/1P2P1PR/2B1KBN1 b - - 0 13",
        legalMoves: [
            "a7a4", "a7a5", "a7a6", "a7a8", "b7b5", "b7b6", "c6c5", "c8d7", "c8e6",
            "e7e5", "e7e6", "g6f6", "g6f7", "g6h6", "g6h7", "g8f6", "g8h6", "h5h4",
            "h8h6", "h8h7",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 36",
        fen: "r4bnr/4p1p1/2p3k1/1p5p/N2P1Pb1/4B3/1P2K1PR/5BN1 w - - 2 19",
        legalMoves: [
            "e2d2", "e2d3", "e2e1", "e2f2", "g1f3",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 49",
        fen: "4rbn1/4pk2/2p3p1/8/p2P1P1R/6K1/1P1B2P1/5B2 b - - 1 25",
        legalMoves: [
            "a4a3", "c6c5", "e7e5", "e7e6", "e8a8", "e8b8", "e8c8", "e8d8", "f7e6",
            "f7f6", "f7g7", "f8g7", "f8h6", "g6g5", "g8f6", "g8h6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 64",
        fen: "8/5k2/3b3n/1Bp3P1/p2p1K1R/B7/1P4P1/8 w - - 1 33",
        legalMoves: [
            "f4e4", "f4f3",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 1, ply 81",
        fen: "5b2/8/4k3/2B5/4K2n/1P1B4/6P1/8 b - - 0 41",
        legalMoves: [
            "e6d7", "e6f6", "e6f7", "f8c5", "f8d6", "f8e7", "f8g7", "f8h6", "h4f3",
            "h4f5", "h4g2", "h4g6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 4",
        fen: "rnbqkbnr/p1ppppp1/7p/1p6/2P5/3P4/PP2PPPP/RNBQKBNR w KQkq b6 0 3",
        legalMoves: [
            "a2a3", "a2a4", "b1a3", "b1c3", "b1d2", "b2b3", "b2b4", "c1d2", "c1e3",
            "c1f4", "c1g5", "c1h6", "c4b5", "c4c5", "d1a4", "d1b3", "d1c2", "d1d2",
            "d3d4", "e1d2", "e2e3", "e2e4", "f2f3", "f2f4", "g1f3", "g1h3", "g2g3",
            "g2g4", "h2h3", "h2h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 9",
        fen: "rnbqkb1r/2ppppp1/P4n1p/8/Q7/3P4/PP2PPPP/RNB1KBNR b KQkq - 0 5",
        legalMoves: [
            "a8a6", "a8a7", "b8a6", "b8c6", "c7c5", "c7c6", "c8a6", "c8b7", "e7e5",
            "e7e6", "f6d5", "f6e4", "f6g4", "f6g8", "f6h5", "f6h7", "g7g5", "g7g6",
            "h6h5", "h8g8", "h8h7",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 16",
        fen: "2bqkbr1/2pppppn/Q1n4p/8/8/3P3N/PP2PPPP/RNB1KB1R w KQ - 1 9",
        legalMoves: [
            "a2a3", "a2a4", "a6a3", "a6a4", "a6a5", "a6a7", "a6a8", "a6b5", "a6b6",
            "a6b7", "a6c4", "a6c6", "a6c8", "b1a3", "b1c3", "b1d2", "b2b3", "b2b4",
            "c1d2", "c1e3", "c1f4", "c1g5", "c1h6", "d3d4", "e1d1", "e1d2", "e2e3",
            "e2e4", "f2f3", "f2f4", "g2g3", "g2g4", "h1g1", "h3f4", "h3g1", "h3g5",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 25",
        fen: "2q1kbr1/1bpppp1n/2n4p/8/P3P3/1P1P3N/4KPPP/RN3B1R b - - 1 13",
        legalMoves: [
            "b7a6", "b7a8", "c6a5", "c6a7", "c6b4", "c6b8", "c6d4", "c6d8", "c6e5",
            "c8a8", "c8b8", "c8d8", "d7d5", "d7d6", "e7e5", "e7e6", "e8d8", "f7f5",
            "f7f6", "f8g7", "g8g2", "g8g3", "g8g4", "g8g5", "g8g6", "g8g7", "g8h8",
            "h6h5", "h7f6", "h7g5",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 36",
        fen: "2q1kb2/2pppp1n/7p/8/P1P2N2/3bKP2/R6P/1N3BrR w - - 0 19",
        legalMoves: [
            "a2a1", "a2a3", "a2b2", "a2c2", "a2d2", "a2e2", "a2f2", "a2g2", "a4a5",
            "b1a3", "b1c3", "b1d2", "c4c5", "e3d2", "e3d3", "e3d4", "e3f2", "f1d3",
            "f1e2", "f1g2", "f1h3", "f4d3", "f4d5", "f4e2", "f4e6", "f4g2", "f4g6",
            "f4h3", "f4h5", "h1g1", "h2h3", "h2h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 49",
        fen: "4kN2/2p1pp1n/7p/2P5/P2p4/3K1P2/7P/R4BrR b - - 0 25",
        legalMoves: [
            "c7c6", "e7e5", "e7e6", "e8d8", "e8f8", "f7f5", "f7f6", "g1f1", "g1g2",
            "g1g3", "g1g4", "g1g5", "g1g6", "g1g7", "g1g8", "g1h1", "h6h5", "h7f6",
            "h7f8", "h7g5",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 64",
        fen: "8/2p2k1N/7p/2P1pp2/P2K1P2/8/7P/2R4R w - - 0 33",
        legalMoves: [
            "d4c3", "d4c4", "d4d3", "d4d5", "d4e3", "d4e5", "f4e5",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 2, ply 81",
        fen: "6k1/8/8/PKP2p1p/5p2/8/7P/R7 b - - 0 41",
        legalMoves: [
            "f4f3", "g8f7", "g8f8", "g8g7", "g8h7", "g8h8", "h5h4",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 4",
        fen: "rnb1kbnr/pp1ppppp/2p5/q7/7P/3P4/PPP1PPP1/RNBQKBNR w KQkq - 1 3",
        legalMoves: [
            "b1c3", "b1d2", "b2b4", "c1d2", "c2c3", "d1d2",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 9",
        fen: "rnb1kbnr/pp1ppppp/2p5/8/5B1P/2NP4/1PP1PPP1/Q3KBNR b Kkq - 0 5",
        legalMoves: [
            "a7a5", "a7a6", "b7b5", "b7b6", "b8a6", "c6c5", "d7d5", "d7d6", "e7e5",
            "e7e6", "e8d8", "f7f5", "f7f6", "g7g5", "g7g6", "g8f6", "g8h6", "h7h5",
            "h7h6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 16",
        fen: "rBb1kbr1/1p1pp1pp/2p2p1n/p7/7P/Q1NP3N/1PP1PPP1/4KB1R w Kq a6 0 9",
        legalMoves: [
            "a3a1", "a3a2", "a3a4", "a3a5", "a3b3", "a3b4", "a3c5", "a3d6", "a3e7",
            "b2b3", "b2b4", "b8a7", "b8c7", "b8d6", "b8e5", "b8f4", "b8g3", "b8h2",
            "c3a2", "c3a4", "c3b1", "c3b5", "c3d1", "c3d5", "c3e4", "d3d4", "e1d1",
            "e1d2", "e2e3", "e2e4", "f2f3", "f2f4", "g2g3", "g2g4", "h1g1", "h1h2",
            "h3f4", "h3g1", "h3g5", "h4h5",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 25",
        fen: "rBb1kr2/1p1p2pp/2p1p2n/p7/7p/1PPP4/4PPP1/3NKB1R b Kq - 0 13",
        legalMoves: [
            "a5a4", "a8a6", "a8a7", "a8b8", "b7b5", "b7b6", "c6c5", "d7d5", "d7d6",
            "e6e5", "e8d8", "e8e7", "e8f7", "f8f2", "f8f3", "f8f4", "f8f5", "f8f6",
            "f8f7", "f8g8", "f8h8", "g7g5", "g7g6", "h4h3", "h6f5", "h6f7", "h6g4",
            "h6g8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 36",
        fen: "1rb3n1/1p1pk1p1/2p5/p3p3/2P5/1P1PP3/5rP1/3NKB1R w - - 0 19",
        legalMoves: [
            "b3b4", "c4c5", "d1b2", "d1c3", "d1f2", "d3d4", "e1f2", "e3e4", "f1e2",
            "g2g3", "g2g4", "h1g1", "h1h2", "h1h3", "h1h4", "h1h5", "h1h6", "h1h7",
            "h1h8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 49",
        fen: "1rb5/1p1p1kp1/2p4n/8/P1P5/3BP1P1/3K4/6NR b - - 0 25",
        legalMoves: [
            "b7b5", "b7b6", "b8a8", "c6c5", "d7d5", "d7d6", "f7e6", "f7e7", "f7e8",
            "f7f6", "f7f8", "f7g8", "g7g5", "g7g6", "h6f5", "h6g4", "h6g8",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 64",
        fen: "8/1p4p1/2B5/2kr2P1/P1P3b1/4P2R/4K3/6N1 w - - 1 33",
        legalMoves: [
            "e2e1", "e2f1", "e2f2", "g1f3", "h3f3",
        ],
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessOracleCase(
        name: "Deterministic python-chess game 3, ply 81",
        fen: "8/6p1/8/6P1/P5bN/1k2P3/7K/7B b - - 0 41",
        legalMoves: [
            "b3a2", "b3a3", "b3a4", "b3b2", "b3b4", "b3c2", "b3c3", "b3c4", "g4c8",
            "g4d1", "g4d7", "g4e2", "g4e6", "g4f3", "g4f5", "g4h3", "g4h5", "g7g6",
        ],
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
]

@Test("Legal move generation matches python-chess oracle", arguments: pythonChessOracleCases)
private func legalMoveGenerationMatchesPythonChessOracle(testCase: PythonChessOracleCase) throws {
    let fenSerializer = FENSerializer()
    let position = try fenSerializer.position(from: testCase.fen)
    let game = Game(position: position)
    let legalMoves = game.legalMoves.map(\.description).sorted()

    #expect(legalMoves == testCase.legalMoves, "\(testCase.name): \(testCase.fen)")
    #expect(game.isCheck == testCase.isCheck, "\(testCase.name)")
    #expect(game.isCheckmate == testCase.isCheckmate, "\(testCase.name)")
    #expect(game.isStalemate == testCase.isStalemate, "\(testCase.name)")

    let roundTrippedPosition = try fenSerializer.position(from: fenSerializer.fen(from: position))
    let roundTrippedMoves = Game(position: roundTrippedPosition).legalMoves.map(\.description).sorted()
    #expect(roundTrippedMoves == legalMoves, "FEN round trip changed legal moves for \(testCase.name)")
}

private struct PythonChessMoveCountOracleCase: Sendable {
    var name: String
    var fen: String
    var legalMoveCount: Int
    var isCheck: Bool
    var isCheckmate: Bool
    var isStalemate: Bool
}

private let pythonChessMoveCountOracleCases: [PythonChessMoveCountOracleCase] = [
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 0, ply 6",
        fen: "rnbqkbn1/ppppp1p1/8/5p1r/3PP3/8/PPP2PPP/RNB1KBNR w KQq - 0 4",
        legalMoveCount: 34,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 0, ply 13",
        fen: "rnbqkbn1/ppppp1p1/7B/3P4/4p1P1/8/PPPK1P2/RN3BNr b q g3 0 7",
        legalMoveCount: 24,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 0, ply 22",
        fen: "rnbqkb2/ppppp1p1/8/3P4/P3p1n1/7N/1PPK1P2/R3r3 w q - 0 12",
        legalMoveCount: 19,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 0, ply 34",
        fen: "rnb1kb2/pp1pp1p1/3p4/5q2/2P3n1/5p1N/1PK5/3r4 w q - 2 18",
        legalMoveCount: 3,
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 0, ply 51",
        fen: "rnb1kb2/pp1p2p1/3p4/4p3/8/5p2/2K4n/8 b q - 0 26",
        legalMoveCount: 17,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 0, ply 73",
        fen: "r1bk4/1p1p2p1/p1n5/3pp1b1/8/1K3p2/7n/8 b - - 3 37",
        legalMoveCount: 29,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 1, ply 6",
        fen: "1nbqkbnr/1ppppppp/8/6B1/1p6/3P4/r1P1PPPP/RN1QKBNR w KQk - 0 4",
        legalMoveCount: 28,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 1, ply 13",
        fen: "1nbqkbnr/2ppBppp/8/1p6/1p6/3P4/4NPPP/RN1QKB1R b KQk - 0 7",
        legalMoveCount: 21,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 1, ply 22",
        fen: "1nb1k1n1/2ppbpp1/8/1p5r/1p6/3P4/3N1PPP/R3KB1R w KQ - 0 12",
        legalMoveCount: 27,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 1, ply 34",
        fen: "1nb1k1n1/2ppbpp1/8/1p6/1p6/3P4/5r2/2NK4 w - - 0 18",
        legalMoveCount: 5,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 1, ply 51",
        fen: "1n2kb2/2p1np2/3p2p1/1p6/3P4/7b/2K5/8 b - - 0 26",
        legalMoveCount: 26,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 1, ply 73",
        fen: "3k4/2p2p2/n5p1/3p2b1/1p6/8/2K5/8 b - - 2 37",
        legalMoveCount: 20,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 2, ply 6",
        fen: "rnbqkbnr/pp1ppp2/2p3p1/7p/7P/7N/PPPPPPPR/RNBQKB2 w Qkq - 0 4",
        legalMoveCount: 20,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 2, ply 13",
        fen: "rnb1kbnr/pp1ppp2/2p3p1/7p/7P/3Q3N/PPPP1PPq/RNB1KB2 b Qkq - 1 7",
        legalMoveCount: 29,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 2, ply 22",
        fen: "r1b1kbnr/pp1npp2/6p1/1p5p/3P3P/8/PPP2K2/RNB5 w kq - 0 12",
        legalMoveCount: 23,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 2, ply 34",
        fen: "r4bnr/1p1k1p2/p2p2p1/1pn3Bp/6bP/8/PPP5/RN1K4 w - - 6 18",
        legalMoveCount: 3,
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 2, ply 51",
        fen: "r3kb2/1p2np1r/p2p2p1/7p/3P2bP/1p6/5K2/RNB5 b - - 5 26",
        legalMoveCount: 32,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 2, ply 73",
        fen: "r3k3/1p2r3/6p1/p1p2p1p/3n2bP/8/6K1/r1b5 b - - 1 37",
        legalMoveCount: 48,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 3, ply 6",
        fen: "r1bqkbnr/p2ppppp/n7/1pp5/8/5PP1/PPPPP1BP/RNBQK1NR w KQkq - 2 4",
        legalMoveCount: 21,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 3, ply 13",
        fen: "r1bqkbnr/p2p1p2/n3p2p/1pp3p1/1P6/2NP1PPB/P1P1P2P/R1BQK1NR b KQkq b3 0 7",
        legalMoveCount: 26,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 3, ply 22",
        fen: "r1b1kbnr/p2p1p2/4p2p/1pp5/1R6/2NP1PPB/n1P1PK1P/3q2NR w kq - 0 12",
        legalMoveCount: 30,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 3, ply 34",
        fen: "r1b1kbnr/p4p2/4p2p/1pp5/8/3P1nP1/2P1P1KP/4R3 w kq - 0 18",
        legalMoveCount: 21,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 3, ply 51",
        fen: "r1b3nr/p1k5/4p2p/2p2pb1/p3P1n1/2KP2P1/2P5/8 b - - 3 26",
        legalMoveCount: 35,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 3, ply 73",
        fen: "4k1nr/p7/7p/4p3/3pp1n1/1K4P1/3bb3/8 b - - 7 37",
        legalMoveCount: 32,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 4, ply 6",
        fen: "r1bqkbnr/ppp2ppp/n2p4/4p3/5P2/N5P1/PPPPP2P/R1BQKBNR w KQkq e6 0 4",
        legalMoveCount: 22,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 4, ply 13",
        fen: "r1bqkbnr/ppp2ppp/n2p4/8/8/N5P1/PPPpK2P/R1BQ1BNR b kq - 1 7",
        legalMoveCount: 35,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 4, ply 22",
        fen: "r1bqkbnr/ppp2ppp/3p4/8/1n2K3/NP4P1/P2Q4/R4BNr w kq - 0 12",
        legalMoveCount: 42,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 4, ply 34",
        fen: "r1bq1knr/pp3ppp/2p5/3pK3/B7/NP4P1/r7/8 w - - 0 18",
        legalMoveCount: 10,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 4, ply 51",
        fen: "r1b2knr/pp3pp1/2p4p/1r6/2Kp4/8/8/8 b - - 3 26",
        legalMoveCount: 33,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 4, ply 73",
        fen: "r1b1k1nr/pp3p2/2p3p1/7p/3p4/1r6/K7/8 b - - 15 37",
        legalMoveCount: 37,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 5, ply 6",
        fen: "rnbqkbnr/pp1ppppp/8/8/1pP5/1Q6/P2PPPPP/RNB1KBNR w KQkq - 0 4",
        legalMoveCount: 32,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 5, ply 13",
        fen: "rnb1kb1r/ppqppppp/7n/2P5/8/2p3P1/P2PPP1P/R1BQKBNR b KQkq - 0 7",
        legalMoveCount: 30,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 5, ply 22",
        fen: "rnb1k2r/pp1p1ppp/4p2n/8/8/2P1b1P1/P4K1P/R1B1QBNR w kq - 0 12",
        legalMoveCount: 6,
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 5, ply 34",
        fen: "rnb1k1r1/pp1p1ppp/4p3/8/2P5/1R3nP1/P4K2/Q6R w q - 0 18",
        legalMoveCount: 44,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 5, ply 51",
        fen: "r1b1k2r/1p1p1ppp/p3p3/2P1R3/7n/6Pn/P1R5/5K2 b q - 7 26",
        legalMoveCount: 26,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 5, ply 73",
        fen: "4r2r/1p3ppp/p2k4/8/5KP1/8/8/8 b - - 0 37",
        legalMoveCount: 31,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 6, ply 6",
        fen: "rnbqkb1r/pppppppp/8/8/7P/8/PPPPPnB1/RNBQK1NR w KQkq - 0 4",
        legalMoveCount: 26,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 6, ply 13",
        fen: "rnbqkb1r/pppppppp/8/5B2/2n4P/7N/P1PPP3/RNB1K2R b KQkq - 3 7",
        legalMoveCount: 26,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 6, ply 22",
        fen: "rnbq1b1r/pppkpppp/7B/8/7P/7N/2n1P3/R3K2R w KQ - 0 12",
        legalMoveCount: 4,
        isCheck: true,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 6, ply 34",
        fen: "1nbq1b1r/rppkp1pp/p7/5p2/7P/2B1n1KN/4P3/7R w - - 6 18",
        legalMoveCount: 27,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 6, ply 51",
        fen: "1nb2br1/B1p1p1pp/p1k5/1p1q3P/8/3nK3/4P1N1/8 b - - 8 26",
        legalMoveCount: 43,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 6, ply 73",
        fen: "2b2br1/6p1/p2kp1p1/1p6/5K2/8/2q5/2n5 b - - 9 37",
        legalMoveCount: 37,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 7, ply 6",
        fen: "r1bqkb1r/p1pppppp/p1n2n2/8/4PP2/8/PPPP2PP/RNBQK1NR w KQkq - 0 4",
        legalMoveCount: 26,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 7, ply 13",
        fen: "r1bqkb1r/p1pppppp/p1n5/3Q4/5P1P/N7/PPP3P1/R1B1KnNR b KQkq - 3 7",
        legalMoveCount: 22,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 7, ply 22",
        fen: "r1bq1b1r/p1pkp1pp/p1n5/5p2/2P2P1P/N6R/PP4P1/R1BK2n1 w - - 0 12",
        legalMoveCount: 23,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 7, ply 34",
        fen: "r1bq1b1r/p1pkp1pp/p1n4B/5p2/7P/nPK5/P7/R7 w - - 0 18",
        legalMoveCount: 18,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 7, ply 51",
        fen: "r1b1kb1r/p1p1p2p/p6p/5p2/7P/nP3n2/P7/5K2 b - - 11 26",
        legalMoveCount: 28,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
    PythonChessMoveCountOracleCase(
        name: "Count oracle game 7, ply 73",
        fen: "r1b1k3/p1p4p/p3p3/5p1p/Pb6/7n/7K/8 b - - 1 37",
        legalMoveCount: 28,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false
    ),
]

@Test("Generated legal move counts match python-chess oracle", arguments: pythonChessMoveCountOracleCases)
private func generatedLegalMoveCountsMatchPythonChessOracle(testCase: PythonChessMoveCountOracleCase) throws {
    let fenSerializer = FENSerializer()
    let position = try fenSerializer.position(from: testCase.fen)
    let game = Game(position: position)

    #expect(game.legalMoves.count == testCase.legalMoveCount, "\(testCase.name): \(testCase.fen)")
    #expect(game.isCheck == testCase.isCheck, "\(testCase.name)")
    #expect(game.isCheckmate == testCase.isCheckmate, "\(testCase.name)")
    #expect(game.isStalemate == testCase.isStalemate, "\(testCase.name)")

    let roundTrippedPosition = try fenSerializer.position(from: fenSerializer.fen(from: position))
    #expect(
        Game(position: roundTrippedPosition).legalMoves.count == testCase.legalMoveCount,
        "FEN round trip changed legal move count for \(testCase.name)"
    )
}
