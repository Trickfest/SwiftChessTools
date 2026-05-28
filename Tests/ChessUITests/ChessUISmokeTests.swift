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
