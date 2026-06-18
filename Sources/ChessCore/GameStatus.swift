//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation

/// Claimable draw rules available to the player to move.
///
/// These claims do not automatically end the game. Call `Game.claimDraw(_:)`
/// when the player or app elects to claim one.
public enum GameDrawClaim: Hashable, Sendable {
    /// The halfmove clock has reached 100 halfmoves.
    case fiftyMoveRule

    /// The current repetition key has occurred at least three times.
    case threefoldRepetition
}

/// Draw reasons that end a game.
///
/// Some reasons are automatic under standard rules, such as stalemate,
/// insufficient material, dead position, seventy-five-move rule, and fivefold
/// repetition. Fifty-move and threefold repetition appear here after a claim is
/// made.
public enum GameDrawReason: Equatable, Sendable {
    /// The player to move has no legal moves and is not in check.
    case stalemate

    /// Neither side has enough material for any checkmate supported by
    /// ChessCore's standard insufficient-material model.
    case insufficientMaterial

    /// Neither side can possibly checkmate by any legal sequence of moves.
    case deadPosition

    /// The halfmove clock has reached 150 halfmoves.
    case seventyFiveMoveRule

    /// The current repetition key has occurred at least five times.
    case fivefoldRepetition

    /// The fifty-move rule was claimed.
    case fiftyMoveRule

    /// Threefold repetition was claimed.
    case threefoldRepetition
}

/// High-level status for the current game position.
///
/// `GameStatus` describes endings ChessCore can derive from standard rules, or
/// an ongoing game with currently available draw claims. App-specific results
/// such as resignation, timeout, adjudication, or agreed draws should be
/// represented by the app around this value.
public enum GameStatus: Equatable, Sendable {
    /// The game is still playable, with any currently available draw claims.
    case ongoing(drawClaims: Set<GameDrawClaim>)

    /// The side to move is checkmated.
    case checkmate(winner: PieceColor)

    /// The game is automatically drawn.
    case draw(GameDrawReason)

    /// Final outcome when this status has one.
    public var outcome: GameOutcome? {
        switch self {
        case .ongoing:
            return nil
        case let .checkmate(winner):
            return .win(winner)
        case .draw:
            return .draw
        }
    }
}

/// Final result for a completed game.
///
/// `GameOutcome` is intentionally smaller than PGN results. Ongoing or
/// externally ended games may not have a ChessCore-derived outcome.
public enum GameOutcome: Equatable, Sendable {
    /// One side won.
    case win(PieceColor)

    /// The game ended in a draw.
    case draw
}

/// Errors thrown while replaying a concrete move list.
public enum GameReplayError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// A move in the replay sequence was illegal at the supplied ply.
    case illegalMove(move: Move, ply: Int)

    /// Human-readable error text.
    public var description: String {
        switch self {
        case let .illegalMove(move, ply):
            return "Illegal replay move \(move) at ply \(ply)."
        }
    }

    /// Localized replay failure text.
    public var errorDescription: String? {
        description
    }
}

/// Errors thrown when safely applying a move to a game.
public enum GameApplyError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// The supplied move was illegal at the current ply.
    case illegalMove(move: Move, ply: Int)

    /// Human-readable error text.
    public var description: String {
        switch self {
        case let .illegalMove(move, ply):
            return "Illegal move \(move) at ply \(ply)."
        }
    }

    /// Localized move-application failure text.
    public var errorDescription: String? {
        description
    }
}

/// Errors thrown when claiming a draw.
public enum GameDrawClaimError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// The supplied draw claim is not currently available.
    case unavailable(GameDrawClaim)

    /// Human-readable error text.
    public var description: String {
        switch self {
        case let .unavailable(claim):
            return "Draw claim is not available: \(claim)."
        }
    }

    /// Localized draw-claim failure text.
    public var errorDescription: String? {
        description
    }
}

/// Position identity used for threefold and fivefold repetition.
///
/// Repetition depends on piece placement, side to move, castling rights, and
/// legal en-passant availability. It deliberately excludes move counters.
public struct GameRepetitionKey: Hashable, Sendable {

    /// Pieces on the board.
    public let board: Board

    /// Side to move.
    public let turn: PieceColor

    /// Castling rights, independent of source ordering.
    public let castlingRights: Set<Piece>

    /// En-passant target when an en-passant capture is legal in this position.
    public let enPassant: Square?

    /// Creates a repetition key for a position.
    public init(position: Position) {
        self.board = position.board
        self.turn = position.state.turn
        self.castlingRights = Set(position.state.castlingRights)
        self.enPassant = Self.legalEnPassantTarget(in: position)
    }

    private static func legalEnPassantTarget(in position: Position) -> Square? {
        guard let target = position.state.enPassant else {
            return nil
        }

        let sourceRank = position.state.turn == .white ? target.rank - 1 : target.rank + 1
        let capturedRank = sourceRank
        guard (0..<8).contains(sourceRank), (0..<8).contains(capturedRank) else {
            return nil
        }

        let capturedSquare = Square(file: target.file, rank: capturedRank)
        guard position.board[capturedSquare] == Piece(kind: .pawn, color: position.state.turn.opposite)
        else {
            return nil
        }

        let rules = StandardRules()
        for fileOffset in [-1, 1] {
            let source = Square(file: target.file + fileOffset, rank: sourceRank)
            guard source.isValid else {
                continue
            }
            guard position.board[source] == Piece(kind: .pawn, color: position.state.turn) else {
                continue
            }
            if rules.legalMovesForPiece(at: source, in: position).contains(Move(from: source, to: target)) {
                return target
            }
        }

        return nil
    }

}
