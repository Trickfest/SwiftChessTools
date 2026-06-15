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

@Test func gameStatusIdentifiesOngoingCheckmateAndStalemate() throws {
    let startingGame = game(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    #expect(startingGame.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(startingGame.outcome == nil)
    #expect(!startingGame.isDraw)
    #expect(!startingGame.isStalemate)

    let checkedGame = game(from: "4k3/8/8/8/8/8/4r3/4K3 w - - 0 1")
    #expect(checkedGame.isCheck)
    #expect(!checkedGame.isCheckmate)
    #expect(checkedGame.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(checkedGame.outcome == nil)

    let checkmateGame = game(
        from: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"
    )
    #expect(checkmateGame.status == .checkmate(winner: .black))
    #expect(checkmateGame.outcome == .win(.black))
    #expect(!checkmateGame.isDraw)
    #expect(!checkmateGame.isStalemate)

    let blackCheckmated = game(from: "7k/6Q1/5K2/8/8/8/8/8 b - - 0 1")
    #expect(blackCheckmated.status == .checkmate(winner: .white))
    #expect(blackCheckmated.outcome == .win(.white))
    #expect(!blackCheckmated.isDraw)

    let stalemateGame = game(from: "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1")
    #expect(stalemateGame.status == .draw(.stalemate))
    #expect(stalemateGame.outcome == .draw)
    #expect(stalemateGame.isDraw)
    #expect(stalemateGame.isStalemate)
}

private struct TerminalStatusCorpusCase: Sendable {
    var name: String
    var fen: String
    var expectedStatus: GameStatus
    var expectedOutcome: GameOutcome?
    var isCheck: Bool
    var isStalemate: Bool
}

private let terminalStatusCorpus: [TerminalStatusCorpusCase] = [
    TerminalStatusCorpusCase(
        name: "Queen promotion mate",
        fen: "1Q2k3/8/4K3/8/8/8/8/8 b - - 0 1",
        expectedStatus: .checkmate(winner: .white),
        expectedOutcome: .win(.white),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Rook underpromotion mate",
        fen: "R7/8/8/8/8/k7/8/KQ6 b - - 0 1",
        expectedStatus: .checkmate(winner: .white),
        expectedOutcome: .win(.white),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Bishop underpromotion mate",
        fen: "B7/8/8/8/8/8/5Q2/K6k b - - 0 1",
        expectedStatus: .checkmate(winner: .white),
        expectedOutcome: .win(.white),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Knight underpromotion discovered-line mate",
        fen: "QN6/8/8/8/8/8/8/k1K5 b - - 0 1",
        expectedStatus: .checkmate(winner: .white),
        expectedOutcome: .win(.white),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Black queen promotion mate",
        fen: "8/8/8/8/8/4k3/8/1q2K3 w - - 0 2",
        expectedStatus: .checkmate(winner: .black),
        expectedOutcome: .win(.black),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Black rook underpromotion mate",
        fen: "kq6/8/K7/8/8/8/8/r7 w - - 0 2",
        expectedStatus: .checkmate(winner: .black),
        expectedOutcome: .win(.black),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Black bishop underpromotion mate",
        fen: "k6K/5q2/8/8/8/8/8/b7 w - - 0 2",
        expectedStatus: .checkmate(winner: .black),
        expectedOutcome: .win(.black),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Black knight underpromotion discovered-line mate",
        fen: "K1k5/8/8/8/8/8/8/qn6 w - - 0 2",
        expectedStatus: .checkmate(winner: .black),
        expectedOutcome: .win(.black),
        isCheck: true,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Promoted-piece stalemate",
        fen: "7k/5K2/5NQ1/8/8/8/8/8 b - - 0 1",
        expectedStatus: .draw(.stalemate),
        expectedOutcome: .draw,
        isCheck: false,
        isStalemate: true
    ),
    TerminalStatusCorpusCase(
        name: "Mirrored promoted-piece stalemate",
        fen: "8/8/8/8/8/5nq1/5k2/7K w - - 0 1",
        expectedStatus: .draw(.stalemate),
        expectedOutcome: .draw,
        isCheck: false,
        isStalemate: true
    ),
    TerminalStatusCorpusCase(
        name: "Same-color bishops with promoted-material shape",
        fen: "8/8/8/8/8/8/3b4/K1k1B1B1 w - - 0 1",
        expectedStatus: .draw(.insufficientMaterial),
        expectedOutcome: .draw,
        isCheck: false,
        isStalemate: false
    ),
    TerminalStatusCorpusCase(
        name: "Same-color bishops across both sides",
        fen: "8/8/8/8/8/8/8/KBkB1b2 w - - 0 1",
        expectedStatus: .draw(.insufficientMaterial),
        expectedOutcome: .draw,
        isCheck: false,
        isStalemate: false
    ),
]

@Test("Terminal position corpus", arguments: terminalStatusCorpus)
private func terminalStatusCorpusMatches(testCase: TerminalStatusCorpusCase) {
    let game = game(from: testCase.fen)

    #expect(game.status == testCase.expectedStatus, "\(testCase.name)")
    #expect(game.outcome == testCase.expectedOutcome, "\(testCase.name)")
    #expect(game.isCheck == testCase.isCheck, "\(testCase.name)")
    #expect(game.isStalemate == testCase.isStalemate, "\(testCase.name)")
    #expect(game.isDraw == (testCase.expectedOutcome == GameOutcome.draw), "\(testCase.name)")
}

@Test func enPassantCheckEvasionKeepsGameOngoing() throws {
    let game = game(from: "4k3/8/8/3pP3/4K3/8/8/8 w - d6 0 1")

    #expect(game.isCheck)
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(game.outcome == nil)
    #expect(game.legalMoves.contains(try Move(string: "e5d6")))

    try applyLegalCoordinate("e5d6", to: game)

    #expect(!game.isCheck)
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
}

@Test func insufficientMaterialDrawsCoverBareKingsAndSingleMinorPieces() {
    let insufficientMaterialFENs = [
        "8/8/8/8/8/8/8/K6k w - - 0 1",
        "7k/8/8/8/8/8/8/KB6 w - - 0 1",
        "7k/8/8/8/8/8/8/KN6 w - - 0 1",
        "k6n/8/8/8/8/8/8/K7 b - - 0 1",
        "7k/8/7b/8/8/8/8/K1B5 w - - 0 1",
        "7k/8/8/8/8/8/8/KB1B4 w - - 0 1",
        "b1b4k/8/8/8/8/8/8/K7 b - - 0 1",
        "b1b4k/8/8/8/8/8/8/KB1B4 w - - 0 1",
    ]

    for fen in insufficientMaterialFENs {
        let game = game(from: fen)
        #expect(game.status == .draw(.insufficientMaterial), "Expected insufficient material: \(fen)")
        #expect(game.outcome == .draw)
        #expect(game.isDraw)
    }
}

@Test func sufficientMaterialIsNotAutomaticallyDrawnByMaterialOnly() {
    let sufficientMaterialFENs = [
        "7k/8/8/8/8/8/P7/K7 w - - 0 1",
        "7k/8/8/8/8/8/8/KR6 w - - 0 1",
        "7k/8/8/8/8/8/8/KQ6 w - - 0 1",
        "7k/8/8/8/8/8/8/KBN5 w - - 0 1",
        "7k/8/8/8/8/8/8/KNN5 w - - 0 1",
        "7k/8/8/8/8/8/8/KN4n1 w - - 0 1",
        "7k/8/8/8/8/8/8/KBB5 w - - 0 1",
        "7k/8/6b1/8/8/8/8/K1B5 w - - 0 1",
        "7k/8/8/8/8/8/8/KBN3b1 w - - 0 1",
    ]

    for fen in sufficientMaterialFENs {
        let game = game(from: fen)
        #expect(!game.isDraw, "Expected material to remain sufficient: \(fen)")
        #expect(game.outcome == nil)
        #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    }
}

@Test func halfmoveClockCreatesFiftyMoveClaimsAndSeventyFiveMoveDraws() {
    let beforeClaim = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 99 1")
    #expect(beforeClaim.drawClaims == Set<GameDrawClaim>())
    #expect(beforeClaim.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(beforeClaim.outcome == nil)

    let fiftyMoveClaim = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 100 1")
    #expect(fiftyMoveClaim.drawClaims == Set<GameDrawClaim>([.fiftyMoveRule]))
    #expect(fiftyMoveClaim.status == .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule])))
    #expect(fiftyMoveClaim.outcome == nil)

    let stillClaimable = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 149 1")
    #expect(stillClaimable.drawClaims == Set<GameDrawClaim>([.fiftyMoveRule]))
    #expect(stillClaimable.status == .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule])))

    let automaticDraw = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 150 1")
    #expect(automaticDraw.drawClaims == Set<GameDrawClaim>())
    #expect(automaticDraw.status == .draw(.seventyFiveMoveRule))
    #expect(automaticDraw.outcome == .draw)
    #expect(automaticDraw.isDraw)
}

@Test func halfmoveDrawRulesUpdateWhenQuietMovesCrossThresholds() throws {
    let claim = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 99 1")
    try applyLegalCoordinate("a2b2", to: claim)

    #expect(claim.position.counter.halfMoves == 100)
    #expect(claim.drawClaims == Set<GameDrawClaim>([.fiftyMoveRule]))
    #expect(claim.status == .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule])))
    #expect(claim.outcome == nil)

    let automaticDraw = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 149 1")
    try applyLegalCoordinate("a2b2", to: automaticDraw)

    #expect(automaticDraw.position.counter.halfMoves == 150)
    #expect(automaticDraw.drawClaims == Set<GameDrawClaim>())
    #expect(automaticDraw.status == .draw(.seventyFiveMoveRule))
    #expect(automaticDraw.outcome == .draw)
}

@Test func pawnMovesAndCapturesResetHalfmoveDrawPressure() throws {
    let pawnMove = game(from: "4k3/8/8/8/8/8/4P3/4K3 w - - 99 1")
    try applyLegalCoordinate("e2e3", to: pawnMove)

    #expect(pawnMove.position.counter.halfMoves == 0)
    #expect(pawnMove.drawClaims == Set<GameDrawClaim>())
    #expect(pawnMove.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(pawnMove.outcome == nil)

    let capture = game(from: "4k3/8/8/8/8/8/rQ6/4K3 w - - 149 1")
    try applyLegalCoordinate("b2a2", to: capture)

    #expect(capture.position.counter.halfMoves == 0)
    #expect(capture.drawClaims == Set<GameDrawClaim>())
    #expect(capture.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(capture.outcome == nil)
}

@Test func drawClaimsCanIncludeFiftyMoveAndThreefoldRepetitionTogether() throws {
    let game = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 92 1")

    try applyQuietKingCycle(to: game)
    try applyQuietKingCycle(to: game)

    let expectedClaims = Set<GameDrawClaim>([.fiftyMoveRule, .threefoldRepetition])
    #expect(game.position.counter.halfMoves == 100)
    #expect(game.currentRepetitionCount == 3)
    #expect(game.drawClaims == expectedClaims)
    #expect(game.status == .ongoing(drawClaims: expectedClaims))
    #expect(game.outcome == nil)
}

@Test func drawClaimsCanBeClaimedAndBecomeDrawStatus() throws {
    let fiftyMove = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 100 1")

    try fiftyMove.claimDraw(.fiftyMoveRule)

    #expect(fiftyMove.claimedDraw == .fiftyMoveRule)
    #expect(fiftyMove.drawClaims == Set<GameDrawClaim>())
    #expect(fiftyMove.status == .draw(.fiftyMoveRule))
    #expect(fiftyMove.outcome == .draw)
    #expect(fiftyMove.isDraw)

    let copy = fiftyMove.copy()
    #expect(copy.claimedDraw == .fiftyMoveRule)
    #expect(copy.drawClaims == Set<GameDrawClaim>())
    #expect(copy.status == .draw(.fiftyMoveRule))

    try applyLegalCoordinate("a2b2", to: fiftyMove)

    #expect(fiftyMove.claimedDraw == nil)
    #expect(fiftyMove.drawClaims == Set<GameDrawClaim>([.fiftyMoveRule]))
    #expect(fiftyMove.status == .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule])))

    let threefold = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 0 1")
    try applyQuietKingCycle(to: threefold)
    try applyQuietKingCycle(to: threefold)

    try threefold.claimDraw(.threefoldRepetition)

    #expect(threefold.claimedDraw == .threefoldRepetition)
    #expect(threefold.drawClaims == Set<GameDrawClaim>())
    #expect(threefold.status == .draw(.threefoldRepetition))
    #expect(threefold.outcome == .draw)
}

@Test func unavailableDrawClaimsThrowAndTerminalStatusesTakePrecedence() throws {
    let noClaim = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 99 1")
    do {
        try noClaim.claimDraw(.fiftyMoveRule)
        Issue.record("Expected unavailable draw claim to throw")
    } catch let error as GameDrawClaimError {
        #expect(error == .unavailable(.fiftyMoveRule))
    } catch {
        Issue.record("Expected GameDrawClaimError, got: \(error)")
    }

    let checkmateWithFiftyMoveClock = game(
        from: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 100 3"
    )
    #expect(checkmateWithFiftyMoveClock.drawClaims == Set<GameDrawClaim>())
    #expect(checkmateWithFiftyMoveClock.status == .checkmate(winner: .black))

    do {
        try checkmateWithFiftyMoveClock.claimDraw(.fiftyMoveRule)
        Issue.record("Expected checkmate to make draw claim unavailable")
    } catch let error as GameDrawClaimError {
        #expect(error == .unavailable(.fiftyMoveRule))
    } catch {
        Issue.record("Expected GameDrawClaimError, got: \(error)")
    }

    let automaticDraw = game(from: "4k3/8/8/8/8/8/Q7/4K3 w - - 150 1")
    #expect(automaticDraw.drawClaims == Set<GameDrawClaim>())
    #expect(automaticDraw.status == .draw(.seventyFiveMoveRule))

    do {
        try automaticDraw.claimDraw(.fiftyMoveRule)
        Issue.record("Expected automatic draw to make draw claim unavailable")
    } catch let error as GameDrawClaimError {
        #expect(error == .unavailable(.fiftyMoveRule))
    } catch {
        Issue.record("Expected GameDrawClaimError, got: \(error)")
    }
}

@Test func checkmateTakesPrecedenceOverAutomaticDrawCounters() {
    let checkmateGame = game(
        from: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 150 3"
    )

    #expect(checkmateGame.status == .checkmate(winner: .black))
    #expect(checkmateGame.outcome == .win(.black))
    #expect(!checkmateGame.isDraw)
}

@Test func statusPrecedencePrefersTerminalAndAutomaticDrawReasons() throws {
    let stalemateWithCounterDraw = game(from: "7k/5K2/6Q1/8/8/8/8/8 b - - 150 1")
    #expect(stalemateWithCounterDraw.status == .draw(.stalemate))
    #expect(stalemateWithCounterDraw.outcome == .draw)

    let insufficientMaterialWithCounterDraw = game(from: "8/8/8/8/8/8/8/K6k w - - 150 1")
    #expect(insufficientMaterialWithCounterDraw.status == .draw(.insufficientMaterial))
    #expect(insufficientMaterialWithCounterDraw.outcome == .draw)

    let fivefoldWithFiftyMoveClaim = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 92 1")
    for _ in 0..<4 {
        try applyQuietKingCycle(to: fivefoldWithFiftyMoveClaim)
    }

    #expect(fivefoldWithFiftyMoveClaim.position.counter.halfMoves == 108)
    #expect(fivefoldWithFiftyMoveClaim.currentRepetitionCount == 5)
    #expect(fivefoldWithFiftyMoveClaim.drawClaims == Set<GameDrawClaim>())
    #expect(fivefoldWithFiftyMoveClaim.status == .draw(.fivefoldRepetition))

    let seventyFiveMoveAndFivefold = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 134 1")
    for _ in 0..<4 {
        try applyQuietKingCycle(to: seventyFiveMoveAndFivefold)
    }

    #expect(seventyFiveMoveAndFivefold.position.counter.halfMoves == 150)
    #expect(seventyFiveMoveAndFivefold.currentRepetitionCount == 5)
    #expect(seventyFiveMoveAndFivefold.drawClaims == Set<GameDrawClaim>())
    #expect(seventyFiveMoveAndFivefold.status == .draw(.seventyFiveMoveRule))
}

@Test func insufficientMaterialDrawCanStillBeReportedWhileSideToMoveIsInCheck() {
    let checkedInsufficientMaterial = game(from: "8/8/8/8/8/8/1b6/K1k1B1B1 w - - 0 1")

    #expect(checkedInsufficientMaterial.isCheck)
    #expect(!checkedInsufficientMaterial.legalMoves.isEmpty)
    #expect(checkedInsufficientMaterial.status == .draw(.insufficientMaterial))
    #expect(checkedInsufficientMaterial.outcome == .draw)
}

@Test func repetitionClaimsAndAutomaticDrawsUseCurrentRepetitionKey() throws {
    let game = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 0 1")
    #expect(game.currentRepetitionCount == 1)
    #expect(game.drawClaims == Set<GameDrawClaim>())

    try applyQuietKingCycle(to: game)
    #expect(game.currentRepetitionCount == 2)
    #expect(game.drawClaims == Set<GameDrawClaim>())
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()))

    try applyQuietKingCycle(to: game)
    #expect(game.currentRepetitionCount == 3)
    #expect(game.drawClaims == Set<GameDrawClaim>([.threefoldRepetition]))
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>([.threefoldRepetition])))
    #expect(game.outcome == nil)

    try applyQuietKingCycle(to: game)
    try applyQuietKingCycle(to: game)
    #expect(game.currentRepetitionCount == 5)
    #expect(game.status == .draw(.fivefoldRepetition))
    #expect(game.outcome == .draw)
}

@Test func repetitionKeyIncludesTurnCastlingAndRelevantEnPassantAvailability() {
    let whiteToMove = position(from: "8/8/8/8/8/6k1/8/R3K3 w Q - 0 1")
    let blackToMove = position(from: "8/8/8/8/8/6k1/8/R3K3 b Q - 0 1")
    let noCastling = position(from: "8/8/8/8/8/6k1/8/R3K3 w - - 0 1")

    #expect(GameRepetitionKey(position: whiteToMove) != GameRepetitionKey(position: blackToMove))
    #expect(GameRepetitionKey(position: whiteToMove) != GameRepetitionKey(position: noCastling))

    let irrelevantEnPassant = position(from: "4k3/8/8/3p4/8/8/4P3/4K3 w - d6 0 1")
    let noEnPassant = position(from: "4k3/8/8/3p4/8/8/4P3/4K3 w - - 0 1")
    #expect(GameRepetitionKey(position: irrelevantEnPassant) == GameRepetitionKey(position: noEnPassant))

    let legalEnPassant = position(from: "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
    let legalEnPassantRemoved = position(from: "4k3/8/8/3pP3/8/8/8/4K3 w - - 0 1")
    #expect(GameRepetitionKey(position: legalEnPassant) != GameRepetitionKey(position: legalEnPassantRemoved))
}

@Test func repetitionKeyIgnoresEnPassantWhenCaptureIsIllegalDueToKingExposure() {
    let whiteIllegalEnPassant = position(from: "4k3/8/8/r4pPK/8/8/8/8 w - f6 0 1")
    let whiteNoEnPassant = position(from: "4k3/8/8/r4pPK/8/8/8/8 w - - 0 1")
    #expect(Game(position: whiteIllegalEnPassant).legalMoves.contains(try! Move(string: "g5f6")) == false)
    #expect(GameRepetitionKey(position: whiteIllegalEnPassant) == GameRepetitionKey(position: whiteNoEnPassant))

    let blackIllegalEnPassant = position(from: "8/8/8/8/R4Ppk/8/8/4K3 b - f3 0 1")
    let blackNoEnPassant = position(from: "8/8/8/8/R4Ppk/8/8/4K3 b - - 0 1")
    #expect(Game(position: blackIllegalEnPassant).legalMoves.contains(try! Move(string: "g4f3")) == false)
    #expect(GameRepetitionKey(position: blackIllegalEnPassant) == GameRepetitionKey(position: blackNoEnPassant))
}

@Test func repetitionCountsUseFullRepetitionKeyInsteadOfBoardOnlyCounts() throws {
    let game = game(from: "8/8/8/8/8/6k1/8/R3K3 w Q - 0 1")

    try applyQuietKingCycle(to: game)

    #expect(game.positionCounts[game.position.board] == 2)
    #expect(game.currentRepetitionCount == 1)
    #expect(game.drawClaims == Set<GameDrawClaim>())
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
}

@Test func gameLikeKnightRepetitionCreatesClaimsAndAutomaticDraws() throws {
    let game = game(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let initialRepetitionKey = GameRepetitionKey(position: game.position)
    let cycle = ["g1f3", "g8f6", "f3g1", "f6g8"]

    for _ in 0..<2 {
        try applyLegalCoordinates(cycle, to: game)
    }

    #expect(GameRepetitionKey(position: game.position) == initialRepetitionKey)
    #expect(game.currentRepetitionCount == 3)
    #expect(game.drawClaims == Set<GameDrawClaim>([.threefoldRepetition]))
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>([.threefoldRepetition])))

    for _ in 0..<2 {
        try applyLegalCoordinates(cycle, to: game)
    }

    #expect(GameRepetitionKey(position: game.position) == initialRepetitionKey)
    #expect(game.currentRepetitionCount == 5)
    #expect(game.status == .draw(.fivefoldRepetition))
    #expect(game.outcome == .draw)
}

@Test func gameCopyPreservesRepetitionCountsAndStatusIndependently() throws {
    let original = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 0 1")
    try applyQuietKingCycle(to: original)
    try applyQuietKingCycle(to: original)

    let copy = original.copy()

    #expect(original.currentRepetitionCount == 3)
    #expect(copy.currentRepetitionCount == 3)
    #expect(copy.status == .ongoing(drawClaims: Set<GameDrawClaim>([.threefoldRepetition])))

    try applyQuietKingCycle(to: copy)
    try applyQuietKingCycle(to: copy)

    #expect(original.currentRepetitionCount == 3)
    #expect(original.status == .ongoing(drawClaims: Set<GameDrawClaim>([.threefoldRepetition])))
    #expect(copy.currentRepetitionCount == 5)
    #expect(copy.status == .draw(.fivefoldRepetition))
}

@Test func gameReplayRebuildsHistoryCountersAndRepetitionState() throws {
    let initialPosition = position(from: PGNSerializer.standardStartingFEN)
    let cycle = ["g1f3", "g8f6", "f3g1", "f6g8"]
    let moves = try (cycle + cycle).map { try Move(string: $0) }

    let replayed = try Game.replay(initialPosition: initialPosition, moves: moves)

    #expect(replayed.moveHistory == moves)
    #expect(replayed.currentRepetitionCount == 3)
    #expect(replayed.drawClaims == Set<GameDrawClaim>([.threefoldRepetition]))
    #expect(replayed.status == .ongoing(drawClaims: Set<GameDrawClaim>([.threefoldRepetition])))
    #expect(
        FENSerializer().fen(from: replayed.position)
            == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 8 5"
    )

    let metadataOnly = Game(position: replayed.position, moveHistory: moves)
    #expect(metadataOnly.moveHistory == moves)
    #expect(metadataOnly.currentRepetitionCount == 1)
    #expect(metadataOnly.drawClaims == Set<GameDrawClaim>())
    #expect(metadataOnly.position == replayed.position)
}

@Test func gameReplayRejectsIllegalMovesWithPlyContext() throws {
    let initialPosition = position(from: PGNSerializer.standardStartingFEN)
    let illegalMove = try Move(string: "e2e5")

    do {
        _ = try Game.replay(initialPosition: initialPosition, moves: [illegalMove])
        Issue.record("Expected illegal replay move to throw")
    } catch let error as GameReplayError {
        #expect(error == .illegalMove(move: illegalMove, ply: 1))
    } catch {
        Issue.record("Expected GameReplayError, got: \(error)")
    }
}

@Test func resetReplacesPositionHistoryCountsAndClaimedDraw() throws {
    let game = game(from: "8/8/8/8/8/6k1/8/R3K3 w - - 0 1")
    try applyQuietKingCycle(to: game)
    try applyQuietKingCycle(to: game)
    try game.claimDraw(.threefoldRepetition)

    let resetPosition = position(from: "4k3/8/8/8/8/8/8/R3K3 w Q - 0 1")
    let metadataHistory = [try Move(string: "e2e4")]

    game.reset(to: resetPosition, moveHistory: metadataHistory)

    #expect(game.position == resetPosition)
    #expect(game.moveHistory == metadataHistory)
    #expect(game.positionCounts == [resetPosition.board: 1])
    #expect(game.repetitionCounts == [GameRepetitionKey(position: resetPosition): 1])
    #expect(game.claimedDraw == nil)
    #expect(game.currentRepetitionCount == 1)
    #expect(game.drawClaims == Set<GameDrawClaim>())
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()))
}

private func game(from fen: String) -> Game {
    return Game(position: position(from: fen))
}

private func position(from fen: String) -> Position {
    return try! FENSerializer().position(from: fen)
}

private func applyQuietKingCycle(to game: Game) throws {
    try applyLegalCoordinates(["e1d1", "g3f3", "d1e1", "f3g3"], to: game)
}

private func applyLegalCoordinates(_ coordinates: [String], to game: Game) throws {
    for coordinate in coordinates {
        try applyLegalCoordinate(coordinate, to: game)
    }
}

private func applyLegalCoordinate(_ coordinate: String, to game: Game) throws {
    let move = try Move(string: coordinate)
    if !game.legalMoves.contains(move) {
        Issue.record("Expected legal move \(coordinate) in \(FENSerializer().fen(from: game.position))")
    }
    game.apply(move: move)
}
