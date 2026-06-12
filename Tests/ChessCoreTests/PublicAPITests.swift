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
