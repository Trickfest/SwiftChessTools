import Testing

import ChessCore
import ChessUI

@Test func chessUITargetImportsCoreAndBuildsModel() {
    let model = ChessboardModel(fen: INITIAL_FEN)
    let serializer = FenSerialization()

    #expect(FenValidation.validateFen(model.fen))
    #expect(serializer.serialize(position: model.game.position) == model.fen)
    #expect(Move(string: "e2e4").description == "e2e4")
}

@Test func setFenWithLanRecordsAnimatedMoveFeedback() {
    let model = ChessboardModel(fen: INITIAL_FEN)
    let move = Move(string: "e2e4")

    model.game.make(move: move)
    let fen = FenSerialization().serialize(position: model.game.position)
    model.setFen(fen, lan: "e2e4")

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
    let model = ChessboardModel(fen: INITIAL_FEN)
    let move = Move(string: "e2e4")

    model.game.make(move: move)
    let fen = FenSerialization().serialize(position: model.game.position)
    model.setFen(fen, lan: "e2e4")

    model.fen = EMPTY_FEN

    #expect(model.lastMoveSquares?.from == nil)
    #expect(model.movingPiece?.from == nil)
    #expect(model.currentMove == nil)
}
