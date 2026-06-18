//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// Complete board state for a single point in a game.
///
/// `Position` is a value-semantic snapshot: board contents, side to move,
/// castling rights, en-passant target, and move counters. It does not contain a
/// move history or repetition counts. Use `Game` when you need to apply moves,
/// track history, or compute status.
///
/// ```swift
/// let position = try FENSerializer().position(from: Position.standardStartingFEN)
/// let game = Game(position: position)
/// print(game.legalMoves.count)
/// ```
public struct Position: Hashable, Sendable {

    /// Full FEN for the standard chess starting position.
    public static let standardStartingFEN =
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    /// Standard chess starting position.
    ///
    /// This value is parsed once from `standardStartingFEN` and can be reused
    /// when constructing games or PGN records from the normal initial board.
    public static let standard = try! FENSerializer().position(from: Self.standardStartingFEN)

    /// State that belongs to a position but is not stored directly on the board.
    ///
    /// FEN stores these fields separately from piece placement. They are
    /// required for correct legal move generation because castling,
    /// en-passant, and side-to-move legality cannot be inferred from occupied
    /// squares alone.
    public struct State: Hashable, Sendable {
        /// Side to move.
        public var turn: PieceColor

        /// Castling rights that are still available.
        public var castlingRights: [Piece]

        /// Target square for a legal en passant capture.
        public var enPassant: Square?

    }

    /// Move counters stored in FEN.
    ///
    /// These counters drive draw-rule behavior and PGN/FEN round trips. The
    /// halfmove clock resets after captures and pawn advances; the fullmove
    /// number increments after Black moves.
    public struct Counter: Hashable, Sendable {
        /// Half-moves since the last capture or pawn advance.
        public var halfMoves: Int

        /// Full-move number, starting at 1 and incrementing after Black moves.
        public var fullMoves: Int
    }

    /// Pieces on the board.
    public var board: Board

    /// Side to move, castling rights, and en passant target.
    public var state: State

    /// Half-move and full-move counters.
    public var counter: Counter

}
