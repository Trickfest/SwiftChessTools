//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// A chess piece with a kind and color.
public struct Piece: Hashable, CustomStringConvertible {

    /// The kind of piece, such as king, rook, or pawn.
    public let kind: PieceKind

    /// The side this piece belongs to.
    public let color: PieceColor

    // MARK: Initialization

    /// Creates a piece with a kind and color.
    public init(kind: PieceKind, color: PieceColor) {
        self.kind = kind
        self.color = color
    }

    /// Creates a piece from a FEN piece character.
    ///
    /// Uppercase characters create white pieces, and lowercase characters
    /// create black pieces.
    public init?(character: Character) {
        guard let kind = PieceKind(rawValue: character.lowercased()) else {
            return nil
        }
        let color: PieceColor = character.isUppercase ? .white : .black
        self.init(kind: kind, color: color)
    }

    // MARK: CustomStringConvertible

    /// FEN character for this piece.
    public var description: String {
        let character = self.kind.rawValue
        return self.color == .white ? character.uppercased() : character.lowercased()
    }

}
