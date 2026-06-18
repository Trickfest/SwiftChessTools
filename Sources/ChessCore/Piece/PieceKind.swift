//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// The type of chess piece, independent of color.
///
/// Raw values are lowercase FEN characters. Combine a kind with `PieceColor`
/// to get a concrete `Piece`.
public enum PieceKind: String, CustomStringConvertible, Sendable {

    /// King.
    case king = "k"

    /// Queen.
    case queen = "q"

    /// Rook.
    case rook = "r"

    /// Bishop.
    case bishop = "b"

    /// Knight.
    case knight = "n"

    /// Pawn.
    case pawn = "p"

    // MARK: CustomStringConvertible

    /// Lowercase FEN character for this kind.
    public var description: String {
        return self.rawValue
    }

}
