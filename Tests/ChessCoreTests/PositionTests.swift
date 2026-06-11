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

@Test func positionCopyIsIndependent() {
    let fenSerializer = FENSerializer()
    let initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    let position = try! fenSerializer.position(from: initialFen)

    var positionCopy = position
    positionCopy.board["e4"] = nil
    positionCopy.state.castlingRights = []
    positionCopy.state.enPassant = Square(coordinate: "e4")
    positionCopy.state.turn = .black
    positionCopy.counter.fullMoves = 100
    positionCopy.counter.halfMoves = 200

    #expect(fenSerializer.fen(from: position) == initialFen)
}
