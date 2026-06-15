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

@Test func serializationTypesArePubliclyInitializable() {
    _ = FENSerializer()
    _ = SANSerializer()
    _ = ChessMoveRecordBuilder()
    _ = PGNSerializer()
    _ = PositionValidator()
    _ = DeadPositionAnalyzer()
}

@Test func parserAPIsArePubliclyUsable() {
    let position = try! FENSerializer().position(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)
    let move = try! Move(string: "e2e4")

    #expect(SANSerializer().san(for: move, in: game) == "e4")
    #expect(FENParsingError.invalidFieldCount(expected: 6, actual: 1).description.isEmpty == false)
    #expect(MoveParsingError.invalidLength("e2").description.isEmpty == false)
    #expect(SANParsingError.emptySAN.description.isEmpty == false)
    #expect(PGNParsingError.emptyInput.description.isEmpty == false)
}

@Test func moveRecordAPIsArePubliclyUsable() {
    let position = try! FENSerializer().position(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let move = try! Move(string: "e2e4")
    let records = try! ChessMoveRecordBuilder().records(initialPosition: position, moves: [move])

    #expect(records == [
        ChessMoveRecord(
            ply: 1,
            fullMoveNumber: 1,
            side: .white,
            move: move,
            san: "e4"
        ),
    ])
    #expect(ChessMoveRecordBuilderError.illegalMove(move: move, ply: 2).description.isEmpty == false)
}

@Test func gameStatusAPIsArePubliclyUsable() {
    let position = try! FENSerializer().position(
        from: "4k3/8/8/8/8/8/Q7/4K3 w - - 100 1"
    )
    let game = Game(position: position)
    let repetitionKey = GameRepetitionKey(position: position)

    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule])))
    #expect(game.drawClaims == Set<GameDrawClaim>([.fiftyMoveRule]))
    #expect(game.currentRepetitionCount == 1)
    #expect(game.outcome == nil)
    #expect(!game.isDraw)
    #expect(!game.isStalemate)
    #expect(repetitionKey.turn == .white)
    #expect(GameStatus.draw(.stalemate).outcome == .draw)
    #expect(GameStatus.checkmate(winner: .black).outcome == .win(.black))
    #expect(GameDrawReason.insufficientMaterial == .insufficientMaterial)
    #expect(GameDrawReason.deadPosition == .deadPosition)
    #expect(GameDrawReason.fiftyMoveRule == .fiftyMoveRule)

    let deadPosition = try! FENSerializer().position(
        from: "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"
    )
    #expect(DeadPositionAnalyzer().isDeadPosition(deadPosition))
    #expect(Game(position: deadPosition).status == .draw(.deadPosition))

    try! game.claimDraw(.fiftyMoveRule)
    #expect(game.claimedDraw == .fiftyMoveRule)
    #expect(game.status == .draw(.fiftyMoveRule))

    game.reset(to: position)
    #expect(game.claimedDraw == nil)
    #expect(game.moveHistory.isEmpty)

    let startingPosition = try! FENSerializer().position(from: PGNSerializer.standardStartingFEN)
    let move = try! Move(string: "e2e4")
    let replayed = try! Game.replay(initialPosition: startingPosition, moves: [move])
    #expect(replayed.moveHistory == [move])
    #expect(GameReplayError.illegalMove(move: move, ply: 1).description.isEmpty == false)
    #expect(GameDrawClaimError.unavailable(.threefoldRepetition).description.isEmpty == false)
}

@Test func positionValidationAPIsArePubliclyUsable() {
    let serializer = FENSerializer()
    let position = try! serializer.validatedPosition(from: PGNSerializer.standardStartingFEN)
    let issues = PositionValidator().issues(in: position)

    #expect(issues.isEmpty)
    #expect(PositionValidationIssue.missingKing(.white).description.isEmpty == false)
    #expect(
        PositionValidationError.invalidPosition([.missingKing(.white)])
            .description
            .isEmpty == false
    )
}

@Test func pgnAPIsArePubliclyUsable() {
    let serializer = PGNSerializer()
    let pgn = """
        [Event "Public API"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4 *
        """
    let game = try! serializer.game(from: pgn)
    let startingPosition = try! FENSerializer().position(from: PGNSerializer.standardStartingFEN)
    let expectedGame = Game(position: startingPosition)
    let move = try! Move(string: "e2e4")
    expectedGame.apply(move: move)

    #expect(game.tagPairs.first == PGNTagPair(name: "Event", value: "Public API"))
    #expect(game.moveRecords == [
        PGNMoveRecord(
            ply: 1,
            moveNumber: 1,
            color: .white,
            san: "e4",
            sourceSAN: "e4",
            move: move
        ),
    ])
    #expect(game.initialPosition == startingPosition)
    #expect(game.finalPosition == expectedGame.position)
    #expect(game.finalStatus == .ongoing(drawClaims: Set<GameDrawClaim>()))
    #expect(game.finalOutcome == nil)
    #expect(game.requiredResultForFinalStatus == nil)
    #expect(game.resultMatchesFinalStatus)
    #expect(game.mainlineMoves == [move])
    #expect(game.tagValue(for: "Event") == "Public API")
    #expect(PGNResult(marker: "1/2-1/2") == .draw)
    #expect(PGNResult(terminalStatus: .checkmate(winner: .white)) == .whiteWins)
    #expect(PGNResult(terminalStatus: .draw(.stalemate)) == .draw)
    #expect(PGNResult(terminalStatus: .ongoing(drawClaims: [])) == nil)
    #expect(PGNNumericAnnotationGlyph(rawValue: 1)?.description == "$1")
    #expect(try! serializer.pgn(moves: [move]).contains("1. e4 *"))
    #expect(try! serializer.pgn(from: game).contains("1. e4 *"))
}
