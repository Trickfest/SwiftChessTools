//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

protocol PieceMoveGenerator {
    func moves(from square: Square, in position: Position) -> [Move]
    func reachableSquares(from square: Square, in position: Position) -> [Square]
}
