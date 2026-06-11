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

import ChessUI

@Test(
    "Valid FEN strings",
    arguments: [
        "8/8/8/8/8/8/8/8 w - - 0 1",
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "rnbqkbnr/pp2pppp/8/2ppP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3",
        "8/8/8/8/8/8/8/8 b - e3 12 42",
    ])
func validFENStrings(fen: String) {
    #expect(FENValidator.isValid(fen))
}

@Test(
    "Invalid FEN strings",
    arguments: [
        "",
        "8/8/8/8/8/8/8/8 w - - 0",
        "8/8/8/8/8/8/8/8 x - - 0 1",
        "8/8/8/8/8/8/8/7 w - - 0 1",
        "8/8/8/8/8/8/8/9 w - - 0 1",
        "8/8/8/8/8/8/8/7Z w - - 0 1",
        "8/8/8/8/8/8/8/8 w KK - 0 1",
        "8/8/8/8/8/8/8/8 w KA - 0 1",
        "8/8/8/8/8/8/8/8 w  - 0 1",
        "8/8/8/8/8/8/8/8 w - z9 0 1",
        "8/8/8/8/8/8/8/8 w - e4 0 1",
        "8/8/8/8/8/8/8/8 b - e6 0 1",
        "8/8/8/8/8/8/8/8 w - - -1 1",
        "8/8/8/8/8/8/8/8 w - - 0 0",
        "8/8/8/8/8/8/8/8 w - - no 1",
    ])
func invalidFENStrings(fen: String) {
    #expect(FENValidator.isValid(fen) == false)
}
