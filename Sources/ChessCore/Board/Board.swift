//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// Stores the pieces on a chess board.
///
/// `Board` is only piece placement. It does not know which side is to move,
/// whether castling is still legal, or whether an en-passant target exists.
/// Those fields live in `Position.State`.
///
/// ```swift
/// var board = Board()
/// board["e4"] = Piece(kind: .pawn, color: .white)
/// print(board[Square(coordinate: "e4")]?.kind == .pawn)
/// ```
public struct Board: Hashable, Sendable {

    internal var bitboards: Bitboards

    internal static let fileCoordinates: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h"]
    internal static let rankCoordinates: [Character] = ["1", "2", "3", "4", "5", "6", "7", "8"]
    internal static var squaresCount: Int {
        self.fileCoordinates.count * self.rankCoordinates.count
    }

    /// Creates an empty board.
    public init() {
        self.bitboards = Bitboards()
    }

    /// Reads or writes a piece by its zero-based square index.
    ///
    /// Indexes follow the package's file-major layout. Prefer the `Square` or
    /// coordinate subscripts at app boundaries because they make call sites
    /// clearer.
    public subscript(index: Int) -> Piece? {
        get {
            let squareMask = Bitboard(1) << index

            var color: PieceColor! = nil
            if self.bitboards.white & squareMask != Bitboard.zero {
                color = .white
            } else if self.bitboards.black & squareMask != Bitboard.zero {
                color = .black
            }
            guard color != nil else {
                return nil
            }

            var kind: PieceKind! = nil
            if self.bitboards.king & squareMask != Bitboard.zero {
                kind = .king
            } else if self.bitboards.queen & squareMask != Bitboard.zero {
                kind = .queen
            } else if self.bitboards.rook & squareMask != Bitboard.zero {
                kind = .rook
            } else if self.bitboards.bishop & squareMask != Bitboard.zero {
                kind = .bishop
            } else if self.bitboards.knight & squareMask != Bitboard.zero {
                kind = .knight
            } else if self.bitboards.pawn & squareMask != Bitboard.zero {
                kind = .pawn
            }

            return Piece(kind: kind, color: color)
        }
        set(piece) {
            let squareMask = Bitboard(1) << index

            self.bitboards.white &= ~squareMask
            self.bitboards.black &= ~squareMask
            self.bitboards.king &= ~squareMask
            self.bitboards.queen &= ~squareMask
            self.bitboards.rook &= ~squareMask
            self.bitboards.bishop &= ~squareMask
            self.bitboards.knight &= ~squareMask
            self.bitboards.pawn &= ~squareMask

            guard let piece = piece else {
                return
            }

            switch piece.color {
            case .white:
                self.bitboards.white |= squareMask
            case .black:
                self.bitboards.black |= squareMask
            }

            switch piece.kind {
            case .king:
                self.bitboards.king |= squareMask
            case .queen:
                self.bitboards.queen |= squareMask
            case .rook:
                self.bitboards.rook |= squareMask
            case .bishop:
                self.bitboards.bishop |= squareMask
            case .knight:
                self.bitboards.knight |= squareMask
            case .pawn:
                self.bitboards.pawn |= squareMask
            }
        }
    }

    /// Reads or writes the piece on a square.
    public subscript(square: Square) -> Piece? {
        get {
            return self[square.index]
        }
        set(piece) {
            self[square.index] = piece
        }
    }

    /// Reads or writes a piece by coordinate, such as `"e4"` or `"d5"`.
    public subscript(coordinate: String) -> Piece? {
        get {
            let square = Square(coordinate: coordinate)
            return self[square.index]
        }
        set(piece) {
            let square = Square(coordinate: coordinate)
            self[square.index] = piece
        }
    }

    /// Returns every occupied square and its piece.
    ///
    /// The returned order is stable for a given board and follows the internal
    /// square-index order. Use this for display, inspection, and rule helpers
    /// that need to scan all pieces.
    public func enumeratedPieces() -> [(Square, Piece)] {
        var pieces = [(Square, Piece)]()

        for index in Int.zero..<Board.squaresCount {
            if let piece = self[index] {
                let square = Square(index: index)
                pieces.append((square, piece))
            }
        }

        return pieces
    }

}
