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
///
/// `Piece` is intentionally small and value-semantic. It is used by `Board`,
/// castling-right state, FEN parsing, and UI rendering.
///
/// ```swift
/// let whiteQueen = Piece(kind: .queen, color: .white)
/// print(whiteQueen.description) // "Q"
/// ```
public struct Piece: Hashable, CustomStringConvertible, Sendable {

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
    /// Uppercase ASCII FEN characters create white pieces, and lowercase ASCII
    /// FEN characters create black pieces. Unicode case-folding lookalikes are
    /// rejected.
    public init?(character: Character) {
        guard character.unicodeScalars.count == 1,
              let value = character.unicodeScalars.first?.value
        else {
            return nil
        }

        let kind: PieceKind
        let color: PieceColor
        switch value {
        case 0x4B: (kind, color) = (.king, .white)   // K
        case 0x51: (kind, color) = (.queen, .white)  // Q
        case 0x52: (kind, color) = (.rook, .white)   // R
        case 0x42: (kind, color) = (.bishop, .white) // B
        case 0x4E: (kind, color) = (.knight, .white) // N
        case 0x50: (kind, color) = (.pawn, .white)   // P
        case 0x6B: (kind, color) = (.king, .black)   // k
        case 0x71: (kind, color) = (.queen, .black)  // q
        case 0x72: (kind, color) = (.rook, .black)   // r
        case 0x62: (kind, color) = (.bishop, .black) // b
        case 0x6E: (kind, color) = (.knight, .black) // n
        case 0x70: (kind, color) = (.pawn, .black)   // p
        default: return nil
        }
        self.init(kind: kind, color: color)
    }

    // MARK: CustomStringConvertible

    /// FEN character for this piece.
    public var description: String {
        let character = self.kind.rawValue
        return self.color == .white ? character.uppercased() : character.lowercased()
    }

}
