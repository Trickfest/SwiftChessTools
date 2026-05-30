import Testing

import ChessCore
import ChessUI

@Test func chessUITargetImportsCoreAndBuildsModel() {
    let model = ChessBoardModel(fen: initialFEN)
    let serializer = FENSerializer()

    #expect(FENValidator.isValid(model.fen))
    #expect(serializer.fen(from: model.game.position) == model.fen)
    #expect(Move(string: "e2e4").description == "e2e4")
}

@Test func setFENWithAnimatedMoveRecordsFeedback() {
    let model = ChessBoardModel(fen: initialFEN)
    let move = Move(string: "e2e4")

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
    let move = Move(string: "e2e4")

    model.game.apply(move: move)
    let fen = FENSerializer().fen(from: model.game.position)
    model.setFEN(fen, animatedMove: move)

    model.fen = emptyFEN

    #expect(model.lastMoveSquares?.from == nil)
    #expect(model.movingPiece?.from == nil)
    #expect(model.animatedMove == nil)
}
