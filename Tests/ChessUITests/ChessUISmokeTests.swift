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
@testable import ChessUI

@Test func chessUITargetImportsCoreAndBuildsModel() {
    let model = ChessBoardModel(fen: initialFEN)
    let serializer = FENSerializer()

    #expect((try? serializer.position(from: model.fen)) != nil)
    #expect(serializer.fen(from: model.game.position) == model.fen)
    #expect(try! Move(string: "e2e4").description == "e2e4")
}

@Test func builtInPieceSetsResolveEveryStandardPiece() {
    let pieces = [
        Piece(kind: .king, color: .white),
        Piece(kind: .queen, color: .white),
        Piece(kind: .rook, color: .white),
        Piece(kind: .bishop, color: .white),
        Piece(kind: .knight, color: .white),
        Piece(kind: .pawn, color: .white),
        Piece(kind: .king, color: .black),
        Piece(kind: .queen, color: .black),
        Piece(kind: .rook, color: .black),
        Piece(kind: .bishop, color: .black),
        Piece(kind: .knight, color: .black),
        Piece(kind: .pawn, color: .black),
    ]

    #expect(ChessPieceSet.availableSets == [
        .sashiteMerida,
        .artDecoMonochrome,
        .brutalistMonochrome,
        .origamiMonochrome,
        .circuitBoardMonochrome,
        .blueprintMonochrome,
        .sportsMonochrome,
    ])

    for pieceSet in ChessPieceSet.availableSets {
        let assetNames = pieces.map { pieceSet.assetName(for: $0) }

        #expect(Set(assetNames).count == pieces.count)
        #expect(assetNames.allSatisfy { $0.hasPrefix("\(pieceSet.rawValue)_") })
        #expect(pieceSet.assetNames.sorted() == assetNames.sorted())
    }
}

@Test func modelCanSelectEachBuiltInPieceSet() {
    let model = ChessBoardModel(fen: initialFEN)

    for pieceSet in ChessPieceSet.availableSets {
        model.pieceSet = pieceSet

        #expect(model.pieceSet == pieceSet)
    }
}

@Test func builtInBoardThemesAreAvailableInDisplayOrder() {
    #expect(ChessBoardTheme.availableThemes == [
        .classicGreen,
        .warmWalnut,
        .blueStudy,
        .marble,
        .blueprint,
        .artDecoMonochrome,
        .circuitBoard,
        .sportsCourt,
    ])

    for boardTheme in ChessBoardTheme.availableThemes {
        #expect(boardTheme.displayName.isEmpty == false)
    }
}

@Test func modelCanSelectEachBuiltInBoardTheme() {
    let model = ChessBoardModel(fen: initialFEN)

    for boardTheme in ChessBoardTheme.availableThemes {
        model.boardTheme = boardTheme

        #expect(model.boardTheme == boardTheme)
    }
}

@Test func coordinateLabelsCanBeConfigured() {
    let model = ChessBoardModel(fen: initialFEN)

    #expect(model.showsCoordinateLabels)

    model.showsCoordinateLabels = false
    #expect(model.showsCoordinateLabels == false)

    let hiddenLabelsModel = ChessBoardModel(
        fen: initialFEN,
        showsCoordinateLabels: false
    )
    #expect(hiddenLabelsModel.showsCoordinateLabels == false)
}

@Test func setFENWithAnimatedMoveRecordsFeedback() {
    let model = ChessBoardModel(fen: initialFEN)
    let move = try! Move(string: "e2e4")

    model.game.apply(move: move)
    let fen = FENSerializer().fen(from: model.game.position)
    model.setFEN(fen, animatedMove: move)

    #expect(model.lastMoveSquares?.from.row == 1)
    #expect(model.lastMoveSquares?.from.column == 4)
    #expect(model.lastMoveSquares?.to.row == 3)
    #expect(model.lastMoveSquares?.to.column == 4)
    #expect(model.movingPiece?.from.row == 1)
    #expect(model.movingPiece?.from.column == 4)
    #expect(model.movingPiece?.to.row == 3)
    #expect(model.movingPiece?.to.column == 4)
    #expect(model.movingPiece?.piece == Piece(kind: .pawn, color: .white))
}

@Test func setFENPreservesTheLiveGameWhenRenderingItsCurrentPosition() throws {
    let model = ChessBoardModel(fen: initialFEN)
    let originalGame = model.game
    let moves = try ["g1f3", "g8f6", "f3g1", "f6g8"].map(Move.init(string:))

    for move in moves {
        try model.game.applyLegal(move: move)
        let fen = FENSerializer().fen(from: model.game.position)
        #expect(model.setFEN(fen, animatedMove: move))
    }

    #expect(model.game === originalGame)
    #expect(model.game.moveHistory == moves)
    #expect(model.game.currentRepetitionCount == 2)
}

@Test func setFENPreservesAClaimedDrawForTheSamePosition() throws {
    let fen = "r3k3/8/8/8/8/8/8/R3K3 w - - 100 1"
    let model = ChessBoardModel(fen: fen)
    let originalGame = model.game
    try model.game.claimDraw(.fiftyMoveRule)

    #expect(model.setFEN(fen))
    #expect(model.game === originalGame)
    #expect(model.game.claimedDraw == .fiftyMoveRule)
    #expect(model.game.status == .draw(.fiftyMoveRule))
}

@Test func setFENClearsPositionSpecificInteractionStateButKeepsAnnotations() throws {
    let model = ChessBoardModel(fen: initialFEN)
    let arrow = ChessBoardArrow(from: "e2", to: "e4")!
    model.selectedSquare = BoardSquare(row: 1, column: 4)
    model.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))
    model.dropTarget = (row: 3, column: 4)
    model.hint("d4")
    model.arrows = [arrow]
    model.presentPromotionPicker(
        piece: Piece(kind: .pawn, color: .white),
        sourceSquare: "e7",
        targetSquare: "e8",
        baseMove: try Move(string: "e7e8")
    )

    #expect(model.setFEN(emptyFEN))

    #expect(model.selectedSquare == nil)
    #expect(model.legalMoveSquares.isEmpty)
    #expect(model.dropTarget == nil)
    #expect(!model.isPromotionPickerPresented)
    #expect(model.promotionPiece == nil)
    #expect(model.promotionSourceSquare == nil)
    #expect(model.promotionTargetSquare == nil)
    #expect(model.promotionBaseMove == nil)
    #expect(model.hintedSquares == [BoardSquare(row: 3, column: 3)])
    #expect(model.arrows.count == 1)
    #expect(model.arrows.first?.from == arrow.from)
    #expect(model.arrows.first?.to == arrow.to)
}

@Test func directFenAssignmentClearsMoveFeedback() {
    let model = ChessBoardModel(fen: initialFEN)
    let move = try! Move(string: "e2e4")

    model.game.apply(move: move)
    let fen = FENSerializer().fen(from: model.game.position)
    model.setFEN(fen, animatedMove: move)

    model.fen = emptyFEN

    #expect(model.lastMoveSquares?.from == nil)
    #expect(model.movingPiece?.from == nil)
    #expect(model.animatedMove == nil)
}

@Test func invalidInitialFENFallsBackToEmptyBoard() {
    let model = ChessBoardModel(fen: "not a fen")

    #expect(model.fen == emptyFEN)
    #expect(model.fenError is FENParsingError)
}

@Test func invalidFENAssignmentKeepsExistingBoard() {
    let model = ChessBoardModel(fen: initialFEN)
    let originalFEN = model.fen

    #expect(model.setFEN("not a fen") == false)
    #expect(model.fen == originalFEN)
    #expect(model.fenError is FENParsingError)
}

@Test func legalMoveHighlightsFollowCurrentSelection() {
    let model = ChessBoardModel(fen: initialFEN)

    model.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))

    #expect(model.legalMoveSquares == [
        BoardSquare(row: 2, column: 4),
        BoardSquare(row: 3, column: 4),
    ])
}

@Test func legalMoveHighlightsCanBeDisabled() {
    let model = ChessBoardModel(fen: initialFEN, showsLegalMoveHighlights: false)

    model.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))

    #expect(model.legalMoveSquares.isEmpty)
}

@Test func hintsCanBeAddedAndCleared() {
    let model = ChessBoardModel(fen: initialFEN)

    model.hint("e4")
    model.hint("bad")
    model.hint(row: 7, column: 6)
    model.hint([BoardSquare(row: 0, column: 1)])

    #expect(model.hintedSquares.contains(BoardSquare(row: 3, column: 4)))
    #expect(model.hintedSquares.contains(BoardSquare(row: 7, column: 6)))
    #expect(model.hintedSquares.contains(BoardSquare(row: 0, column: 1)))
    #expect(model.hintedSquares.count == 3)

    model.clearHint()
    #expect(model.hintedSquares.isEmpty)
}

@Test func invalidHintAndHighlightCoordinatesAreIgnored() {
    let model = ChessBoardModel(fen: initialFEN)
    model.hint("a0")
    model.hint("a9")
    model.hint(BoardSquare(row: -1, column: 0))
    model.hint(row: 8, column: 7)

    #expect(model.hintedSquares.isEmpty)

    model.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))
    #expect(!model.legalMoveSquares.isEmpty)
    model.updateLegalMoveHighlights(for: BoardSquare(row: Int.max, column: Int.min))
    #expect(model.legalMoveSquares.isEmpty)
}

@MainActor
@Test func timedHintsRejectInvalidDurationsAndReplaceEarlierCleanup() async throws {
    let model = ChessBoardModel(fen: initialFEN)

    model.hint("e4", for: .nan)
    #expect(model.hintedSquares.isEmpty)
    model.hint("e4", for: .infinity)
    #expect(model.hintedSquares.isEmpty)

    model.hint("e4", for: 0.02)
    model.hint("d4", for: 0)
    model.hint("c4")
    try await Task.sleep(for: .milliseconds(50))
    await Task.yield()
    #expect(model.hintedSquares == [BoardSquare(row: 3, column: 2)])

    model.clearHint()
    model.hint("e4", for: 0.02)
    try await Task.sleep(for: .milliseconds(50))
    for _ in 0..<100 where !model.hintedSquares.isEmpty {
        await Task.yield()
    }
    #expect(model.hintedSquares.isEmpty)
}

@Test func boardArrowsCanBeConfiguredAndCleared() {
    let primaryArrow = ChessBoardArrow(
        from: BoardSquare(row: 1, column: 4),
        to: BoardSquare(row: 3, column: 4),
        style: .primarySuggestion,
        label: "Best move"
    )
    let coordinateArrow = ChessBoardArrow(
        from: "d2",
        to: "d4",
        style: .secondarySuggestion
    )
    let invalidArrow = ChessBoardArrow(from: "z9", to: "d4")
    let model = ChessBoardModel(
        fen: initialFEN,
        arrows: [primaryArrow]
    )

    #expect(model.arrows.count == 1)
    #expect(model.arrows[0].from == BoardSquare(row: 1, column: 4))
    #expect(model.arrows[0].to == BoardSquare(row: 3, column: 4))
    #expect(model.arrows[0].label == "Best move")
    #expect(coordinateArrow?.from == BoardSquare(row: 1, column: 3))
    #expect(coordinateArrow?.to == BoardSquare(row: 3, column: 3))
    #expect(invalidArrow == nil)

    if let coordinateArrow {
        model.arrows.append(coordinateArrow)
    }
    #expect(model.arrows.count == 2)

    model.clearArrows()
    #expect(model.arrows.isEmpty)
}

@Test func promotionPickerStateCanBePresentedAndDismissed() {
    let model = ChessBoardModel(fen: "7k/4P3/8/8/8/8/8/4K3 w - - 0 1")
    let pawn = Piece(kind: .pawn, color: .white)
    let move = try! Move(string: "e7e8")

    model.presentPromotionPicker(
        piece: pawn,
        sourceSquare: "e7",
        targetSquare: "e8",
        baseMove: move
    )

    #expect(model.isPromotionPickerPresented)
    #expect(model.promotionPiece == pawn)
    #expect(model.promotionSourceSquare == "e7")
    #expect(model.promotionTargetSquare == "e8")
    #expect(model.promotionBaseMove == move)

    model.dismissPromotionPicker()

    #expect(model.isPromotionPickerPresented == false)
    #expect(model.promotionPiece == nil)
    #expect(model.promotionSourceSquare == nil)
    #expect(model.promotionTargetSquare == nil)
    #expect(model.promotionBaseMove == nil)
}

@Test func promotionArtworkUsesThePromotingPawnColorNotPerspective() throws {
    let model = ChessBoardModel(
        fen: "4k3/8/8/8/8/8/4p3/7K b - - 0 1",
        perspective: .white
    )
    model.presentPromotionPicker(
        piece: Piece(kind: .pawn, color: .black),
        sourceSquare: "e2",
        targetSquare: "e1",
        baseMove: try Move(string: "e2e1")
    )

    #expect(model.promotionDisplayColor == .black)
    #expect(
        model.pieceSet.assetName(for: Piece(kind: .queen, color: model.promotionDisplayColor))
            .contains("_bQ")
    )
}

@Test func promotionChoiceIsOnlyRequiredForPawnsReachingLastRank() {
    let whitePawn = Piece(kind: .pawn, color: .white)
    let blackPawn = Piece(kind: .pawn, color: .black)
    let whiteKnight = Piece(kind: .knight, color: .white)
    let model = ChessBoardModel(fen: emptyFEN)

    #expect(model.requiresPromotionChoice(piece: whitePawn, move: try! Move(string: "e7e8")))
    #expect(model.requiresPromotionChoice(piece: blackPawn, move: try! Move(string: "e2e1")))
    #expect(model.requiresPromotionChoice(piece: whitePawn, move: try! Move(string: "e6e7")) == false)
    #expect(model.requiresPromotionChoice(piece: whiteKnight, move: try! Move(string: "g7h8")) == false)
}

@Test func modelConfigurationUsesSafeDefaults() {
    let model = ChessBoardModel(
        fen: initialFEN,
        perspective: .black,
        boardTheme: .blueStudy,
        showsCoordinateLabels: false,
        interactionMode: .freeSetup,
        showsLegalMoveHighlights: false,
        moveAnimationDuration: -2,
        showsLastMoveHighlight: false
    )

    #expect(model.perspective == .black)
    #expect(model.shouldFlipBoard)
    #expect(model.boardTheme == .blueStudy)
    #expect(model.showsCoordinateLabels == false)
    #expect(model.interactionMode == .freeSetup)
    #expect(model.showsLegalMoveHighlights == false)
    #expect(model.moveAnimationDuration == 0)
    #expect(model.showsLastMoveHighlight == false)
}

@Test func mutableAnimationDurationIsNormalized() {
    let model = ChessBoardModel(fen: initialFEN)

    model.moveAnimationDuration = -.infinity
    #expect(model.moveAnimationDuration == 0)
    model.moveAnimationDuration = .nan
    #expect(model.moveAnimationDuration == 0)
    model.moveAnimationDuration = 1_000
    #expect(model.moveAnimationDuration == 60)
}

@Test func disablingLegalMoveHighlightsClearsExistingMarkers() {
    let model = ChessBoardModel(fen: initialFEN)
    model.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))
    #expect(!model.legalMoveSquares.isEmpty)

    model.showsLegalMoveHighlights = false
    #expect(model.legalMoveSquares.isEmpty)
}

@MainActor
@Test func viewMoveHandlerDoesNotCreateAModelOwnershipCycle() {
    weak var weakModel: ChessBoardModel?

    do {
        let model = ChessBoardModel(fen: initialFEN)
        let owner = MoveHandlerOwner(model: model)
        weakModel = model

        let view = ChessBoardView(model: model).onMove { [owner] _ in
            _ = owner.model
        }
        withExtendedLifetime(view) {}
    }

    #expect(weakModel == nil)
}

private final class MoveHandlerOwner {
    let model: ChessBoardModel

    init(model: ChessBoardModel) {
        self.model = model
    }
}

@Test func moveAnimationCleanupFallbackAddsGracePeriodAfterAnimationDuration() {
    #expect(ChessBoardMoveAnimationTiming.sourceSettleDelayMilliseconds == 20)
    #expect(ChessBoardMoveAnimationTiming.cleanupGracePeriodMilliseconds == 100)
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: 0) == 100)
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: 0.45) == 550)
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: 0.451) == 551)
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: 1) == 1_100)
}

@Test func moveAnimationCleanupFallbackTreatsInvalidDurationsAsGracePeriodOnly() {
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: -1) == 100)
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: .nan) == 100)
    #expect(ChessBoardMoveAnimationTiming.fallbackCleanupDelayMilliseconds(for: .infinity) == 100)
}

@Test func zeroDurationMoveAnimationSkipsTemporaryMovingPiece() throws {
    let model = ChessBoardModel(fen: initialFEN, moveAnimationDuration: 0)
    let move = try Move(string: "e2e4")

    model.game.apply(move: move)
    model.setFEN(FENSerializer().fen(from: model.game.position), animatedMove: move)

    #expect(model.movingPiece == nil)
    #expect(model.lastMoveSquares != nil)
}

@Test func interactionModesDescribeMoveReportingPolicy() {
    #expect(ChessBoardInteractionMode.allCases == [
        .readOnly,
        .legalMovesOnly,
        .reportsIllegalAttempts,
        .freeSetup,
    ])
}

@Test func moveAttemptCarriesMoveContext() throws {
    let move = try Move(string: "e2e4")
    let attempt = ChessBoardMoveAttempt(
        move: move,
        isLegal: true,
        sourceSquare: "e2",
        targetSquare: "e4",
        coordinateMove: "e2e4"
    )

    #expect(attempt.move == move)
    #expect(attempt.isLegal)
    #expect(attempt.sourceSquare == "e2")
    #expect(attempt.targetSquare == "e4")
    #expect(attempt.coordinateMove == "e2e4")
    #expect(attempt.promotion == nil)
}

@Test func clearLastMoveHighlightKeepsOtherMoveFeedback() {
    let model = ChessBoardModel(fen: initialFEN)
    let move = try! Move(string: "e2e4")

    model.game.apply(move: move)
    model.setFEN(FENSerializer().fen(from: model.game.position), animatedMove: move)

    #expect(model.lastMoveSquares != nil)
    #expect(model.movingPiece != nil)

    model.clearLastMoveHighlight()

    #expect(model.lastMoveSquares == nil)
    #expect(model.movingPiece != nil)
}
