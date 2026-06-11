//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

class StepMoveGenerator: RangeMoveGenerator {

    private let offsets: [(Int, Int)]

    init(offsets: [(Int, Int)]) {
        self.offsets = offsets
    }

    func reachableSquares(from square: Square, in position: Position) -> [Square] {
        return self.offsets
            .map { square.translate(file: $0.0, rank: $0.1) }
            .filter {
                $0.isValid
                    && position.board.bitboards.bitboard(for: position.state.turn) & $0.bitboardMask
                        == 0
            }
    }

}
