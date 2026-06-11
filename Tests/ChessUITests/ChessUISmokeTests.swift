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
import ChessUI

@Test func chessUITargetImportsCoreAndBuildsModel() {
    let model = ChessBoardModel(fen: initialFEN)
    let serializer = FENSerializer()

    #expect(FENValidator.isValid(model.fen))
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
        allowsOpponentMoves: true,
        showsLegalMoveHighlights: false,
        moveAnimationDuration: -2,
        showsLastMoveHighlight: false
    )

    #expect(model.perspective == .black)
    #expect(model.shouldFlipBoard)
    #expect(model.boardTheme == .blueStudy)
    #expect(model.allowsOpponentMoves)
    #expect(model.showsLegalMoveHighlights == false)
    #expect(model.moveAnimationDuration == 0)
    #expect(model.showsLastMoveHighlight == false)
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
