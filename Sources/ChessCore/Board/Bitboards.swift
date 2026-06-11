//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

typealias Bitboard = UInt64

struct Bitboards: Hashable {

    var white = Bitboard.zero
    var black = Bitboard.zero
    var king = Bitboard.zero
    var queen = Bitboard.zero
    var rook = Bitboard.zero
    var bishop = Bitboard.zero
    var knight = Bitboard.zero
    var pawn = Bitboard.zero

    func bitboard(for color: PieceColor) -> Bitboard {
        return color == .white ? white : black
    }

}
