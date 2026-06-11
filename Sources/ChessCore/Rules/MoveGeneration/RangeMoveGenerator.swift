//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

protocol RangeMoveGenerator: PieceMoveGenerator {

}

extension RangeMoveGenerator {

    func moves(from square: Square, in position: Position) -> [Move] {
        return self.reachableSquares(from: square, in: position)
            .map { Move(from: square, to: $0) }
    }

}
