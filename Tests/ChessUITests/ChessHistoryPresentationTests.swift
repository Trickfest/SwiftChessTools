// Licensed under the MIT License. See LICENSE and NOTICE.md.

import Testing
import SwiftUI
import ChessCore
@testable import ChessUI

@Suite struct ChessHistoryPresentationTests {
    @Test func displaysCompleteReplayStateAcrossRepeatedJumps() throws {
        let moves = try ["g1f3", "g8f6", "f3g1", "f6g8", "g1f3", "g8f6", "f3g1", "f6g8"].map(Move.init(string:))
        let timeline = try GameTimeline(moves: moves)
        let model = ChessBoardModel()
        for ply in [8, 0, 4, 1, 7, 8, 0] {
            let expected = try timeline.game(atPly: ply)
            model.setGame(expected)
            #expect(model.game !== expected)
            #expect(model.game.position == expected.position)
            #expect(model.game.moveHistory == expected.moveHistory)
            #expect(model.game.currentRepetitionCount == expected.currentRepetitionCount)
            #expect(model.game.status == expected.status)
            #expect(model.game.legalMoves == expected.legalMoves)
            #expect(model.lastMoveSquares?.from.coordinate == expected.moveHistory.last?.from.description)
            #expect(model.lastMoveSquares?.to.coordinate == expected.moveHistory.last?.to.description)
            #expect(model.animatedMove == nil)
            #expect(model.movingPiece == nil)
        }
        #expect(timeline.moveCount == 8)
    }

    @Test func gameCopiesAreIsolatedInBothDirectionsAndPreserveClaims() throws {
        let live = Game()
        let model = ChessBoardModel()
        model.setGame(live)
        try live.applyLegal(move: Move(string: "e2e4"))
        #expect(model.game.position == .standard)
        try model.game.applyLegal(move: Move(string: "d2d4"))
        #expect(live.moveHistory.map(\.description) == ["e2e4"])
        #expect(model.game.moveHistory.map(\.description) == ["d2d4"])

        let claimed = Game(position: try FENSerializer().position(from: "r3k3/8/8/8/8/8/8/R3K3 w - - 100 1"))
        try claimed.claimDraw(.fiftyMoveRule)
        model.setGame(claimed)
        #expect(model.game.claimedDraw == .fiftyMoveRule)
        #expect(model.game.status == .draw(.fiftyMoveRule))
        claimed.reset(to: .standard)
        #expect(model.game.claimedDraw == .fiftyMoveRule)
    }

    @Test(arguments: [
        ("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1", ["e1g1", "e8c8"]),
        ("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 42", ["e5d6"]),
        ("4k3/P7/8/8/8/8/8/4K3 w - - 0 42", ["a7a8q"]),
        ("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 42", ["c7c5", "g1f3"]),
        (initialFEN, ["f2f3", "e7e5", "g2g4", "d8h4"]),
        ("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1", [])
    ])
    func specialPositionsRetainRulesState(_ fixture: (String, [String])) throws {
        let timeline = try GameTimeline(initialPosition: FENSerializer().position(from: fixture.0),
                                        moves: fixture.1.map(Move.init(string:)))
        let model = ChessBoardModel()
        for ply in (0...timeline.moveCount).reversed() {
            let expected = try timeline.game(atPly: ply)
            model.setGame(expected)
            #expect(model.game.position == expected.position)
            #expect(model.game.legalMoves == expected.legalMoves)
            #expect(model.game.status == expected.status)
            #expect(model.game.moveHistory == expected.moveHistory)
        }
    }

    @Test func replacingGameClearsTransientStateAndPreservesPreferences() throws {
        let model = ChessBoardModel(perspective: .black, boardTheme: .blueStudy,
                                    pieceSet: .sashiteMerida, interactionMode: .readOnly)
        model.coordinateLabelPlacement = .outside
        model.showsCoordinateLabels = false
        model.pieceRenderingScaleOverrides = [.sashiteMerida: 0.7]
        model.size = 320
        model.isWaiting = true
        model.moveAnimationDuration = 0.9
        model.showsLastMoveHighlight = false
        model.showsLegalMoveHighlights = false
        model.lastMoveHighlightColor = .purple
        model.hint("d4")
        model.arrows = [ChessBoardArrow(from: "e2", to: "e4")!]
        model.selectedSquare = BoardSquare(row: 1, column: 4)
        model.legalMoveSquares = [BoardSquare(row: 3, column: 4)]
        model.dropTarget = (3, 4)
        model.presentPromotionPicker(piece: Piece(kind: .pawn, color: .white),
                                     sourceSquare: "e7", targetSquare: "e8", baseMove: try Move(string: "e7e8"))
        model.animatedMove = try Move(string: "e2e4")
        model.movingPiece = (Piece(kind: .pawn, color: .white), BoardSquare(row: 1, column: 4), BoardSquare(row: 3, column: 4))
        _ = model.setFEN("invalid")
        let oldSurface = model.displayedGameID
        var callbackCount = 0
        model.onMove = { _ in callbackCount += 1 }
        model.setGame(Game())
        #expect(model.displayedGameID != oldSurface)
        #expect(model.selectedSquare == nil && model.legalMoveSquares.isEmpty && model.dropTarget == nil)
        #expect(!model.isPromotionPickerPresented && model.promotionPiece == nil)
        #expect(model.promotionSourceSquare == nil && model.promotionTargetSquare == nil && model.promotionBaseMove == nil)
        #expect(model.animatedMove == nil && model.movingPiece == nil && model.lastMoveSquares == nil)
        #expect(model.fenError == nil)
        #expect(model.perspective == .black && model.boardTheme == .blueStudy && model.pieceSet == .sashiteMerida)
        #expect(model.coordinateLabelPlacement == .outside && !model.showsCoordinateLabels)
        #expect(model.pieceRenderingScaleOverrides == [.sashiteMerida: 0.7])
        #expect(model.size == 320 && model.isWaiting && model.interactionMode == .readOnly)
        #expect(model.moveAnimationDuration == 0.9 && !model.showsLastMoveHighlight && !model.showsLegalMoveHighlights)
        #expect(model.lastMoveHighlightColor == .purple)
        #expect(model.hintedSquares == [BoardSquare(row: 3, column: 3)] && model.arrows.count == 1)
        model.onMove(ChessBoardMoveAttempt(move: try Move(string: "e2e4"), isLegal: true,
                                          sourceSquare: "e2", targetSquare: "e4", coordinateMove: "e2e4"))
        #expect(callbackCount == 1)
    }

    @Test func scrollingPoliciesHandleRootsInvalidSelectionAndGrowth() throws {
        let timeline = try GameTimeline(moves: ["e2e4", "e7e5", "g1f3", "b8c6"].map(Move.init(string:)))
        let records = timeline.moveRecords
        #expect(ChessMoveListScrollBehavior.latestMove.target(records: records, selectedPly: 1, overflows: true) == .end)
        #expect(ChessMoveListScrollBehavior.latestMove.target(records: records, selectedPly: 4, overflows: false) == nil)
        #expect(ChessMoveListScrollBehavior.selectedMove.target(records: records, selectedPly: 0, overflows: true) == .start)
        for ply in [nil, -1, 5] as [Int?] {
            #expect(ChessMoveListScrollBehavior.selectedMove.target(records: records, selectedPly: ply, overflows: true) == nil)
        }
        for count in [2, 4] {
            #expect(ChessMoveListScrollBehavior.selectedMove.target(records: Array(records.prefix(count)), selectedPly: 1, overflows: true) == .move(1))
        }
        #expect(ChessMoveListScrollBehavior.selectedMove.target(records: [], selectedPly: 0, overflows: true) == nil)
    }
}
