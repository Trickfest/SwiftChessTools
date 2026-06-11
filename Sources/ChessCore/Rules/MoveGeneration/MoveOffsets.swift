//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

class MoveOffsets {

    private(set) lazy var diagonal = [
        (-1, -1), (1, 1), (-1, 1), (1, -1),
    ]
    private(set) lazy var orthogonal = [
        (-1, 0), (0, 1), (1, 0), (0, -1),
    ]
    private(set) lazy var allDirections = {
        self.orthogonal + self.diagonal
    }()
    private(set) lazy var knight = [
        (-2, 1), (-1, 2), (1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1),
    ]
    private(set) lazy var pawnCaptures = [
        (-1, 1), (1, 1),
    ]

}
