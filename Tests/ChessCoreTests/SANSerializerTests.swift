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

let testables: [(String, String, String)] = [
    // Basic pawn move.
    ("e4", "e2e4", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"),

    // Basic piece moves.
    ("Nc6", "b8c6", "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2"),
    ("Re1", "f1e1", "r1b1kb1r/ppppqppp/2n5/4P3/2Bpn3/5N2/PPP2PPP/RNBQ1RK1 w kq - 1 7"),
    ("Ke2", "e1e2", "r1bqk1nr/pppp1ppp/2n5/2b5/2BpP3/5N2/PPP2PPP/RNBQK2R w KQkq - 2 5"),

    // Disambiguated piece moves.
    ("Nbd4", "b3d4", "1n2k1n1/8/8/8/8/1N3N2/8/4K3 w - - 0 1"),
    ("Nfd4", "f3d4", "1n2k1n1/8/8/8/8/1N3N2/8/4K3 w - - 0 1"),
    ("Nbd2", "b1d2", "r1b1kb1r/pppp1pp1/1qn4p/4P3/3p2nB/1B3N2/PPP2PPP/RN1Q1RK1 w kq - 2 10"),

    // Piece captures.
    ("Nxe5", "c6e5", "r1bqkbnr/pppp1ppp/2n5/4N3/4P3/8/PPPP1PPP/RNBQKB1R b KQkq - 0 3"),
    ("Nbxd4", "b3d4", "1n2k1n1/8/8/8/3p4/1N3N2/8/4K3 w - - 0 1"),
    ("Nfxd4", "f3d4", "1n2k1n1/8/8/8/3p4/1N3N2/8/4K3 w - - 0 1"),
    ("N1xf3", "g1f3", "4k3/8/8/6N1/8/5p2/8/4K1N1 w - - 0 1"),
    ("N5xf3", "g5f3", "4k3/8/8/6N1/8/5p2/8/4K1N1 w - - 0 1"),
    ("Nb2c4", "b2c4", "7k/8/1N6/8/8/8/1N1N4/4K3 w - - 0 1"),
    ("Qab2", "a1b2", "4k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1"),
    ("Qbb2", "b1b2", "4k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1"),
    ("Qcb2", "c1b2", "4k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1"),
    ("Rab1", "a1b1", "4k3/8/8/8/8/8/1R6/R1R1K3 w - - 0 1"),
    ("Rbb1", "b2b1", "4k3/8/8/8/8/8/1R6/R1R1K3 w - - 0 1"),
    ("Rcb1", "c1b1", "4k3/8/8/8/8/8/1R6/R1R1K3 w - - 0 1"),
    ("Ba1b2", "a1b2", "4k3/8/8/8/8/B7/8/B1B1K3 w - - 0 1"),
    ("B3b2", "a3b2", "4k3/8/8/8/8/B7/8/B1B1K3 w - - 0 1"),
    ("Bcb2", "c1b2", "4k3/8/8/8/8/B7/8/B1B1K3 w - - 0 1"),
    ("Nab3", "a1b3", "4k3/8/8/8/8/8/3N4/N1N1K3 w - - 0 1"),
    ("Ncb3", "c1b3", "4k3/8/8/8/8/8/3N4/N1N1K3 w - - 0 1"),
    ("Ndb3", "d2b3", "4k3/8/8/8/8/8/3N4/N1N1K3 w - - 0 1"),

    // Pawn captures.
    ("exd4", "e5d4", "r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq - 0 3"),
    ("exf6", "e5f6", "r1bqkb1r/pppppppp/2n2n2/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 1 3"),
    ("exd6", "e5d6", "rnbqkbnr/pp2pppp/8/2ppP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3"),
    ("exd6+", "e5d6", "4k3/8/8/3pP3/8/8/8/4R2K w - d6 0 1"),
    ("bxc6", "b7c6", "4kb1r/1p1n1pp1/1qR1p1n1/p2p4/3P3p/1P3N1P/P2N1PPB/3Q1RK1 b k - 0 17"),
    ("exd5", "e6d5", "r1bqkb1r/pp1n1ppp/2p1pn2/3P2B1/3P4/2N1P3/PP3PPP/R2QKBNR b KQkq - 0 6"),

    // Castling.
    ("O-O", "e1g1", "r2q1rk1/ppp1bppp/2np1n2/4p3/2BPP1b1/2N1BN2/PPP1QPPP/R3K2R w KQ - 8 8"),
    ("O-O-O", "e1c1", "r2q1rk1/ppp1bppp/2np1n2/4p3/2BPP1b1/2N1BN2/PPP1QPPP/R3K2R w KQ - 8 8"),
    ("O-O", "e8g8", "r3k2r/ppp1bppp/2np1n2/4p3/2BPP1b1/2N1BN2/PPP1QPPP/R3K2R b kq - 8 8"),
    ("O-O-O", "e8c8", "r3k2r/ppp1bppp/2np1n2/4p3/2BPP1b1/2N1BN2/PPP1QPPP/R3K2R b kq - 8 8"),

    // Check suffixes.
    ("Qe6+", "f5e6", "rnb1kbnr/ppp1pppp/8/5q2/3P4/5N2/PPP2PPP/RNBQKB1R b KQkq - 2 4"),
    ("d7+", "d6d7", "4k3/8/3P4/8/8/8/8/4K3 w - - 0 1"),
    ("O-O-O+", "e1c1", "3k4/8/8/8/8/8/8/R3K3 w Q - 0 1"),
    ("O-O+", "e8g8", "4k2r/8/8/8/8/8/8/5K2 b k - 0 1"),
    ("O-O-O+", "e8c8", "r3k3/8/8/8/8/8/8/3K4 b q - 0 1"),

    // Checkmate suffix.
    ("Qxg2#", "g3g2", "r3k3/pb3p2/1pp4p/3p4/N2P2r1/1P1BP1q1/P5Q1/1RR3K1 b q - 1 26"),

    // Pawn promotions.
    ("a8=Q", "a7a8q", "8/P4pk1/6p1/6Pp/3b3P/8/8/4K3 w - - 0 1"),
    ("a1=N", "a2a1n", "4k3/8/8/7p/6p1/2N3P1/p4PKP/8 b - - 0 1"),
    ("e8=R+", "e7e8r", "r6k/4P3/1R4Q1/8/7p/7P/6PK/8 w - - 1 42"),
    ("exd8=Q+", "e7d8q", "3r3k/4P3/8/8/8/8/8/4K3 w - - 0 1"),
    ("cxb8=Q#", "c7b8q", "1r2k3/2P5/4K3/8/8/8/8/8 w - - 0 1"),
    ("a8=R#", "a7a8r", "8/P7/8/8/8/k7/8/KQ6 w - - 0 1"),
    ("a8=B#", "a7a8b", "8/P7/8/8/8/8/5Q2/K6k w - - 0 1"),
    ("axb8=N#", "a7b8n", "Qr6/P7/8/8/8/8/8/k1K5 w - - 0 1"),
    ("a1=R#", "a2a1r", "kq6/8/K7/8/8/8/p7/8 b - - 0 1"),
    ("a1=B#", "a2a1b", "k6K/5q2/8/8/8/8/p7/8 b - - 0 1"),
    ("axb1=N#", "a2b1n", "K1k5/8/8/8/8/8/p7/qR6 b - - 0 1"),
]

// MARK: Serialization

func san(for move: String, in fen: String) -> String {
    let position = try! FENSerializer().position(from: fen)
    let game = Game(position: position)
    let move = try! Move(string: move)
    return SANSerializer().san(for: move, in: game)
}

@Test func testSerialization() {
    testables.forEach {
        #expect($0.0 == san(for: $0.1, in: $0.2))
    }
}

// MARK: Deserialization

func move(from san: String, in fen: String) -> String {
    let position = try! FENSerializer().position(from: fen)
    let game = Game(position: position)
    return try! SANSerializer().move(for: san, in: game).description
}

@Test func testDeserialization() {
    testables.forEach {
        #expect($0.1 == move(from: $0.0, in: $0.2))
    }
}

private struct SANLegalMoveRoundTripCase: Sendable {
    var name: String
    var fen: String
}

private let sanLegalMoveRoundTripCases: [SANLegalMoveRoundTripCase] = [
    SANLegalMoveRoundTripCase(
        name: "Three queens can share destinations",
        fen: "4k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "Three rooks can share destinations",
        fen: "4k3/8/8/8/8/8/1R6/R1R1K3 w - - 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "Three bishops can share destinations",
        fen: "4k3/8/8/8/8/B7/8/B1B1K3 w - - 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "Three knights can share destinations",
        fen: "4k3/8/8/8/8/8/3N4/N1N1K3 w - - 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "En passant can evade check",
        fen: "4k3/8/8/3pP3/4K3/8/8/8 w - d6 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "En passant can give discovered check",
        fen: "4k3/8/8/3pP3/8/8/4R3/4K3 w - d6 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "Black queen-side castling can give check",
        fen: "r3k3/8/8/8/8/8/8/3K4 b q - 0 1"
    ),
    SANLegalMoveRoundTripCase(
        name: "Dense promoted-material position",
        fen: "n1bqkbnr/P1P1P1P1/8/8/8/8/p1p1p1p1/N1BQKBNR w - - 0 1"
    ),
]

@Test("Every legal move round trips through SAN in stress positions", arguments: sanLegalMoveRoundTripCases)
private func everyLegalMoveRoundTripsThroughSANInStressPositions(
    testCase: SANLegalMoveRoundTripCase
) throws {
    let serializer = SANSerializer()
    let game = Game(position: try FENSerializer().position(from: testCase.fen))
    let legalMoves = game.legalMoves.sorted { $0.description < $1.description }
    var seenSAN: Set<String> = []

    #expect(!legalMoves.isEmpty, "\(testCase.name)")

    for move in legalMoves {
        let san = serializer.san(for: move, in: game)
        #expect(!san.isEmpty, "\(testCase.name), move \(move)")
        #expect(seenSAN.insert(san).inserted, "\(testCase.name), duplicate SAN \(san)")
        #expect(try serializer.move(for: san, in: game) == move, "\(testCase.name), SAN \(san)")
    }
}

@Test func parseAndReplayShortSANGame() {
    let serializer = SANSerializer()
    let fenSerializer = FENSerializer()
    let game = Game(position: try! fenSerializer.position(from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))
    let sanMoves = ["e4", "e5", "Bc4", "Nc6", "Qh5", "Nf6", "Qxf7#"]

    for san in sanMoves {
        let move = try! serializer.move(for: san, in: game)
        #expect(serializer.san(for: move, in: game) == san)
        game.apply(move: move)
    }

    #expect(
        fenSerializer.fen(from: game.position)
            == "r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4"
    )
    #expect(game.isCheckmate)
}

@Test func deserializationAcceptsZeroCastlingNotation() {
    let game = Game(position: try! FENSerializer().position(
        from: "r2q1rk1/ppp1bppp/2np1n2/4p3/2BPP1b1/2N1BN2/PPP1QPPP/R3K2R w KQ - 8 8"
    ))

    #expect(try! SANSerializer().move(for: "0-0", in: game).description == "e1g1")
}

@Test func deserializationToleratesOptionalAndDecorativeCheckSuffixes() {
    let start = Game(position: try! FENSerializer().position(from: PGNSerializer.standardStartingFEN))
    #expect(try! SANSerializer().move(for: "e4+", in: start).description == "e2e4")
    #expect(try! SANSerializer().move(for: "e4#", in: start).description == "e2e4")

    let scholarMate = Game(position: try! FENSerializer().position(
        from: "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4"
    ))
    #expect(try! SANSerializer().move(for: "Qxf7", in: scholarMate).description == "h5f7")
    #expect(try! SANSerializer().move(for: "Qxf7+", in: scholarMate).description == "h5f7")
    #expect(try! SANSerializer().move(for: "Qxf7#", in: scholarMate).description == "h5f7")
}

@Test func deserializationKeepsPawnFilesDistinctFromPieceLetters() {
    let game = Game(position: try! FENSerializer().position(
        from: "8/rP6/np2p2k/1PR2p2/Pb6/5P2/q7/2K5 b - - 0 66"
    ))

    #expect(try! SANSerializer().move(for: "Bxc5", in: game).description == "b4c5")
    #expect(try! SANSerializer().move(for: "bxc5", in: game).description == "b6c5")
}

@Test func deserializationRejectsMissingDisambiguationAndCoordinateNotation() {
    let ambiguousKnights = Game(position: try! FENSerializer().position(
        from: "1n2k1n1/8/8/8/8/1N3N2/8/4K3 w - - 0 1"
    ))
    do {
        _ = try SANSerializer().move(for: "Nd4", in: ambiguousKnights)
        Issue.record("Expected ambiguous missing-disambiguation SAN to fail")
    } catch let error as SANParsingError {
        #expect(error == .noMatchingLegalMove("Nd4"))
    } catch {
        Issue.record("Expected SANParsingError, got: \(error)")
    }

    let start = Game(position: try! FENSerializer().position(from: PGNSerializer.standardStartingFEN))
    do {
        _ = try SANSerializer().move(for: "e2e4", in: start)
        Issue.record("Expected coordinate notation to fail SAN parsing")
    } catch let error as SANParsingError {
        #expect(error == .noMatchingLegalMove("e2e4"))
    } catch {
        Issue.record("Expected SANParsingError, got: \(error)")
    }
}

@Test func deserializationFailureIsReported() {
    let game = Game(position: try! FENSerializer().position(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    ))

    do {
        _ = try SANSerializer().move(for: "", in: game)
        Issue.record("Expected empty SAN parsing to fail")
    } catch let error as SANParsingError {
        #expect(error == .emptySAN)
    } catch {
        Issue.record("Expected SANParsingError, got: \(error)")
    }

    do {
        _ = try SANSerializer().move(for: "Qzz", in: game)
        Issue.record("Expected invalid SAN parsing to fail")
    } catch let error as SANParsingError {
        #expect(error == .noMatchingLegalMove("Qzz"))
    } catch {
        Issue.record("Expected SANParsingError, got: \(error)")
    }
}
