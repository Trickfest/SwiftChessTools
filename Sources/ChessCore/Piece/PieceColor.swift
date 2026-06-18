//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// The side a piece belongs to.
///
/// `PieceColor` is also used for side-to-move state, game outcomes, and UI
/// perspective. Use `opposite` when toggling turns or interpreting captures.
public enum PieceColor: Equatable, Sendable {

    /// The white side.
    case white

    /// The black side.
    case black

    /// The other side.
    public var opposite: PieceColor {
        return self == .white ? .black : .white
    }

}
