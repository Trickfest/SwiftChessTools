//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation
import Testing
import ChessCore

@Suite struct GameTimelineTests {
    @Test func emptyTimelineAndPublicExample() throws {
        var timeline = try GameTimeline()
        #expect(timeline.initialPosition == .standard)
        #expect(timeline.moveCount == 0)
        #expect(timeline.moves.isEmpty)
        #expect(timeline.moveRecords.isEmpty)
        #expect(try timeline.position(atPly: 0) == .standard)
        #expect(try timeline.game(atPly: 0).moveHistory.isEmpty)

        let record = try timeline.append(Move(string: "e2e4"))
        var selectedPly = record.ply
        #expect(selectedPly == 1)
        #expect(record.san == "e4")
        selectedPly = 0
        let displayedGame = try timeline.game(atPly: selectedPly)
        #expect(displayedGame.position == .standard)
        #expect(timeline.moveCount == 1)
        try timeline.replaceContinuation(afterPly: selectedPly, with: [Move(string: "d2d4")])
        selectedPly += 1
        #expect(selectedPly == timeline.moveCount)
        #expect(timeline.moveRecords.map(\.san) == ["d4"])
    }

    @Test func blackRootUsesRelativePliesAndOriginalMoveNumbers() throws {
        let root = try position("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 42")
        let timeline = try GameTimeline(initialPosition: root, moves: moves("c7c5", "g1f3", "d7d6"))
        #expect(timeline.initialPosition == root)
        #expect(timeline.moveRecords.map(\.ply) == [1, 2, 3])
        #expect(timeline.moveRecords.map(\.fullMoveNumber) == [42, 43, 43])
        #expect(timeline.moveRecords.map(\.side) == [.black, .white, .black])
        #expect(timeline.moveRecords.map(\.san) == ["c5", "Nf3", "d6"])
        try expectReplayMatches(timeline)
    }

    @Test(arguments: [-1, 0], [0, -1])
    func invalidInitialCounters(halfMoves: Int, fullMoves: Int) throws {
        var root = Position.standard
        root.counter.halfMoves = halfMoves
        root.counter.fullMoves = fullMoves
        #expect(throws: GameTimelineError.invalidInitialCounters(halfMoves: halfMoves, fullMoves: fullMoves)) {
            try GameTimeline(initialPosition: root)
        }
    }

    @Test func negativeClockWithOtherwiseValidRoot() throws {
        var root = Position.standard
        root.counter.halfMoves = -1
        #expect(throws: GameTimelineError.invalidInitialCounters(halfMoves: -1, fullMoves: 1)) {
            try GameTimeline(initialPosition: root)
        }
    }

    @Test func semanticRootErrorsRemainPositionValidationErrors() throws {
        var root = Position.standard
        root.board["e1"] = nil
        let issues = PositionValidator().issues(in: root)
        #expect(issues.contains(.missingKing(.white)))
        #expect(throws: PositionValidationError.invalidPosition(issues)) {
            try GameTimeline(initialPosition: root)
        }
    }

    @Test(arguments: [Int.min, -1, 3, Int.max])
    func invalidIndicesNeverMutate(ply: Int) throws {
        var timeline = try GameTimeline(moves: moves("e2e4", "e7e5"))
        let original = timeline
        let error = GameTimelineError.invalidPly(ply: ply, moveCount: 2)
        #expect(throws: error) { try timeline.game(atPly: ply) }
        #expect(throws: error) { try timeline.position(atPly: ply) }
        #expect(throws: error) {
            try timeline.replaceContinuation(afterPly: ply, with: moves("a1a8"))
        }
        try expectSameTimeline(timeline, original)
    }

    @Test func emptyTimelineRejectsNonzeroPly() throws {
        var timeline = try GameTimeline()
        #expect(throws: GameTimelineError.invalidPly(ply: 1, moveCount: 0)) {
            try timeline.replaceContinuation(afterPly: 1, with: [])
        }
        #expect(timeline.moveCount == 0)
        try timeline.replaceContinuation(afterPly: 0, with: [])
        #expect(try timeline.position(atPly: 0) == .standard)
    }

    @Test func illegalConstructionReportsAbsolutePly() throws {
        let illegal = try Move(string: "e4e6")
        #expect(throws: GameTimelineError.illegalMove(move: illegal, ply: 3)) {
            try GameTimeline(moves: moves("e2e4", "e7e5") + [illegal])
        }
    }

    @Test func appendMatchesBulkConstructionAndFailureIsAtomic() throws {
        let line = try moves("e2e4", "e7e5", "g1f3", "b8c6", "f1b5")
        var timeline = try GameTimeline()
        for (index, move) in line.enumerated() {
            let record = try timeline.append(move)
            #expect(record == timeline.moveRecords.last)
            #expect(record.ply == index + 1)
        }
        try expectSameTimeline(timeline, GameTimeline(moves: line))
        let original = timeline
        let illegal = try Move(string: "a7a4")
        #expect(throws: GameTimelineError.illegalMove(move: illegal, ply: 6)) {
            try timeline.append(illegal)
        }
        try expectSameTimeline(timeline, original)
    }

    @Test func replacementIsAllOrNothingAndKeepsPrefixRecords() throws {
        var timeline = try GameTimeline(moves: moves("e2e4", "e7e5", "g1f3", "b8c6"))
        let original = timeline
        let illegal = try Move(string: "e4e6")
        #expect(throws: GameTimelineError.illegalMove(move: illegal, ply: 3)) {
            try timeline.replaceContinuation(afterPly: 1, with: moves("c7c5") + [illegal])
        }
        try expectSameTimeline(timeline, original)
        try timeline.replaceContinuation(afterPly: 1, with: moves("c7c5", "g1f3"))
        #expect(timeline.moveRecords.first == original.moveRecords.first)
        #expect(timeline.moveRecords.map(\.san) == ["e4", "c5", "Nf3"])
        try expectSameTimeline(timeline, GameTimeline(moves: moves("e2e4", "c7c5", "g1f3")))
    }

    @Test func replacementBoundarySemantics() throws {
        let original = try GameTimeline(moves: moves("e2e4", "e7e5", "g1f3", "b8c6"))
        var timeline = original
        try timeline.replaceContinuation(afterPly: 1, with: Array(original.moves.dropFirst()))
        try expectSameTimeline(timeline, original)
        try timeline.replaceContinuation(afterPly: 1, with: [original.moves[1]])
        #expect(timeline.moveCount == 2) // Same next move still replaces the whole suffix.
        try timeline.replaceContinuation(afterPly: 2, with: moves("g1f3", "b8c6"))
        try expectSameTimeline(timeline, original)
        try timeline.replaceContinuation(afterPly: 2, with: [])
        #expect(timeline.moves == Array(original.moves.prefix(2)))
        try timeline.replaceContinuation(afterPly: 0, with: moves("d2d4", "d7d5"))
        #expect(timeline.initialPosition == .standard)
        #expect(timeline.moveRecords.map(\.san) == ["d4", "d5"])
        try timeline.replaceContinuation(afterPly: 0, with: [])
        try expectSameTimeline(timeline, GameTimeline())
    }

    @Test func specialMovesUseCorrectReplayStateAndSAN() throws {
        let fixtures: [(String, [String], [String])] = [
            ("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1", ["e1g1", "e8c8"], ["O-O", "O-O-O"]),
            ("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 42", ["e5d6"], ["exd6"]),
            ("4k3/P7/8/8/8/8/8/4K3 w - - 7 42", ["a7a8q"], ["a8=Q+"]),
            ("4k3/P7/8/8/8/8/8/4K3 w - - 7 42", ["a7a8n"], ["a8=N"])
        ]
        for (fen, coordinates, san) in fixtures {
            let root = try position(fen)
            let line = try coordinates.map(Move.init(string:))
            let timeline = try GameTimeline(initialPosition: root, moves: line)
            #expect(timeline.moveRecords.map(\.san) == san)
            try expectReplayMatches(timeline)
            var edited = try GameTimeline(initialPosition: root)
            try edited.replaceContinuation(afterPly: 0, with: line)
            try expectSameTimeline(edited, timeline)
        }
        let ep = try GameTimeline(initialPosition: position(fixtures[1].0), moves: moves("e5d6"))
        let end = try ep.position(atPly: 1)
        #expect(end.board["d5"] == nil)
        #expect(end.board["d6"] == Piece(kind: .pawn, color: .white))
        #expect(end.state.enPassant == nil)
        #expect(end.counter.halfMoves == 0)
    }

    @Test func checkmateAndStalemateRootsAreReadableButCannotContinue() throws {
        let mate = try GameTimeline(moves: moves("f2f3", "e7e5", "g2g4", "d8h4"))
        #expect(mate.moveRecords.last?.san == "Qh4#")
        #expect(try mate.game(atPly: 4).status == .checkmate(winner: .black))
        #expect(try mate.game(atPly: 3).outcome == nil)
        for fen in [
            FENSerializer().fen(from: try mate.position(atPly: 4)),
            "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"
        ] {
            var timeline = try GameTimeline(initialPosition: position(fen))
            let game = try timeline.game(atPly: 0)
            #expect(game.outcome != nil)
            #expect(game.legalMoves.isEmpty)
            let illegal = try Move(string: "h8h7")
            #expect(throws: GameTimelineError.illegalMove(move: illegal, ply: 1)) {
                try timeline.append(illegal)
            }
            #expect(timeline.moves.isEmpty)
        }
        let stalemate = try GameTimeline(initialPosition: position("7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"))
        #expect(try stalemate.game(atPly: 0).status == .draw(.stalemate))
    }

    @Test func repetitionAndClaimsRebuildFromEachPrefix() throws {
        let cycle = try moves("g1f3", "g8f6", "f3g1", "f6g8")
        let timeline = try GameTimeline(moves: Array(repeating: cycle, count: 4).flatMap { $0 })
        #expect(try timeline.game(atPly: 0).currentRepetitionCount == 1)
        #expect(try timeline.game(atPly: 4).currentRepetitionCount == 2)
        #expect(try timeline.game(atPly: 8).drawClaims == [.threefoldRepetition])
        #expect(try timeline.game(atPly: 16).status == .draw(.fivefoldRepetition))
        for _ in 0..<3 { try expectReplayMatches(timeline) }
        let rootAtEnd = try GameTimeline(initialPosition: timeline.position(atPly: 16))
        #expect(try rootAtEnd.game(atPly: 0).currentRepetitionCount == 1)
        #expect(try rootAtEnd.game(atPly: 0).drawClaims.isEmpty)
    }

    @Test func halfmoveClaimsAndAutomaticDrawAllowLegalAnalysisContinuation() throws {
        for clock in [99, 149, 150] {
            let root = try position("4k3/8/8/8/8/8/Q7/4K3 w - - \(clock) 42")
            var timeline = try GameTimeline(initialPosition: root)
            try timeline.append(Move(string: "a2b2"))
            let end = try timeline.game(atPly: 1)
            #expect(end.position.counter.halfMoves == clock + 1)
            if clock == 99 {
                #expect(end.drawClaims == [.fiftyMoveRule])
            } else {
                #expect(end.status == .draw(.seventyFiveMoveRule))
            }
            try timeline.replaceContinuation(afterPly: 1, with: moves("e8f8"))
            try expectSameTimeline(timeline, GameTimeline(initialPosition: root, moves: moves("a2b2", "e8f8")))
        }
    }

    @Test func otherAutomaticDrawsAllowLegalAnalysisContinuation() throws {
        for (fen, expected) in [
            ("4k3/8/8/8/8/8/8/4K3 w - - 0 1", GameDrawReason.insufficientMaterial),
            ("7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1", .deadPosition)
        ] {
            let root = try position(fen)
            let game = Game(position: root)
            #expect(game.status == .draw(expected))
            let move = try #require(game.legalMoves.first)
            var timeline = try GameTimeline(initialPosition: root)
            try timeline.append(move)
            try expectSameTimeline(timeline, GameTimeline(initialPosition: root, moves: [move]))
        }
        let cycle = try moves("g1f3", "g8f6", "f3g1", "f6g8")
        var repeated = try GameTimeline(moves: Array(repeating: cycle, count: 4).flatMap { $0 })
        try repeated.append(cycle[0])
        #expect(repeated.moveCount == 17)
    }

    @Test func returnedGamesPositionsAndCopiedTimelinesAreIndependent() throws {
        let cycle = try moves("g1f3", "g8f6", "f3g1", "f6g8")
        let original = try GameTimeline(moves: cycle + cycle)
        let claimed = try original.game(atPly: 8)
        let independent = try original.game(atPly: 8)
        #expect(claimed !== independent)
        try claimed.claimDraw(.threefoldRepetition)
        #expect(claimed.status == .draw(.threefoldRepetition))
        #expect(independent.claimedDraw == nil)
        #expect(try original.game(atPly: 8).claimedDraw == nil)
        try claimed.applyLegal(move: "e2e4")
        claimed.reset(to: .standard)
        #expect(independent.moveHistory == cycle + cycle)

        var copied = original
        try copied.replaceContinuation(afterPly: 0, with: moves("d2d4"))
        try copied.append(Move(string: "d7d5"))
        #expect(original.moves == cycle + cycle)
        #expect(copied.moveRecords.map(\.san) == ["d4", "d5"])
        var root = original.initialPosition
        root.board["e1"] = nil
        var displayed = try original.position(atPly: 8)
        displayed.board["e8"] = nil
        #expect(try original.position(atPly: 8) == .standardWithCounters(halfMoves: 8, fullMoves: 5))
    }

    @Test func timelineCanCrossAnActorBoundaryAsAValue() async throws {
        let timeline = try GameTimeline(moves: moves("e2e4"))
        let position = try await Task.detached {
            var local = timeline
            try local.append(Move(string: "e7e5"))
            return try local.position(atPly: 2)
        }.value
        #expect(position.state.turn == .white)
        #expect(timeline.moveCount == 1)
    }

    @Test func thousandPlyHistoryRetainsRecordsAndRepetition() throws {
        let cycle = try moves("g1f3", "g8f6", "f3g1", "f6g8")
        let line = Array(repeating: cycle, count: 250).flatMap { $0 }
        let timeline = try GameTimeline(moves: line)
        #expect(timeline.moveCount == 1000)
        #expect(timeline.moveRecords.last?.ply == 1000)
        #expect(timeline.moveRecords.last?.fullMoveNumber == 500)
        for ply in [1000, 0, 999, 500, 1, 1000] {
            let actual = try timeline.game(atPly: ply)
            #expect(actual.moveHistory == Array(line.prefix(ply)))
            #expect(actual.currentRepetitionCount == ply / 4 + 1)
        }
    }

    @Test func errorsHavePublicReadableDescriptions() throws {
        let errors: [GameTimelineError] = [
            .invalidPly(ply: -1, moveCount: 2),
            .invalidInitialCounters(halfMoves: -1, fullMoves: 0),
            .illegalMove(move: try Move(string: "e2e5"), ply: 1)
        ]
        for error in errors {
            #expect(!error.description.isEmpty)
            #expect(error.errorDescription == error.description)
            #expect(error.localizedDescription == error.description)
        }
    }

    private func moves(_ strings: String...) throws -> [Move] {
        try strings.map(Move.init(string:))
    }

    private func position(_ fen: String) throws -> Position {
        try FENSerializer().validatedPosition(from: fen)
    }

    private func expectSameTimeline(_ actual: GameTimeline, _ expected: GameTimeline) throws {
        #expect(actual.initialPosition == expected.initialPosition)
        #expect(actual.moves == expected.moves)
        #expect(actual.moveRecords == expected.moveRecords)
        try expectReplayMatches(actual)
    }

    private func expectReplayMatches(_ timeline: GameTimeline) throws {
        #expect(timeline.moveRecords == (try ChessMoveRecordBuilder().records(
            initialPosition: timeline.initialPosition, moves: timeline.moves
        )))
        for ply in (0...timeline.moveCount).reversed() {
            let expected = try Game.replay(initialPosition: timeline.initialPosition, moves: Array(timeline.moves.prefix(ply)))
            let actual = try timeline.game(atPly: ply)
            #expect(actual.position == expected.position)
            #expect(FENSerializer().fen(from: actual.position) == FENSerializer().fen(from: expected.position))
            #expect(actual.moveHistory == expected.moveHistory)
            #expect(actual.positionCounts == expected.positionCounts)
            #expect(actual.repetitionCounts == expected.repetitionCounts)
            #expect(actual.status == expected.status)
            #expect(actual.drawClaims == expected.drawClaims)
            #expect(actual.isCheck == expected.isCheck)
            #expect(actual.claimedDraw == nil)
            #expect(try timeline.position(atPly: ply) == actual.position)
        }
    }
}

private extension Position {
    static func standardWithCounters(halfMoves: Int, fullMoves: Int) -> Position {
        var position = Position.standard
        position.counter.halfMoves = halfMoves
        position.counter.fullMoves = fullMoves
        return position
    }
}
