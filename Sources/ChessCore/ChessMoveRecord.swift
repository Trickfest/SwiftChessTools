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

/// A display-ready move entry captured while replaying a legal move sequence.
public struct ChessMoveRecord: Identifiable, Equatable, Sendable {
    /// One-based ply index within the move sequence.
    public let ply: Int

    /// Full-move number shown beside this move.
    public let fullMoveNumber: Int

    /// Side that made the move.
    public let side: PieceColor

    /// Coordinate move that was applied.
    public let move: Move

    /// Standard Algebraic Notation for `move` in the pre-move position.
    public let san: String

    /// Stable identifier for SwiftUI lists.
    public var id: Int { ply }

    /// Creates a display-ready move entry.
    public init(
        ply: Int,
        fullMoveNumber: Int,
        side: PieceColor,
        move: Move,
        san: String
    ) {
        self.ply = ply
        self.fullMoveNumber = fullMoveNumber
        self.side = side
        self.move = move
        self.san = san
    }
}

/// Errors thrown while building display-ready move records.
public enum ChessMoveRecordBuilderError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case illegalMove(move: Move, ply: Int)

    public var description: String {
        switch self {
        case let .illegalMove(move, ply):
            "Move \(move) is not legal at ply \(ply)."
        }
    }

    public var errorDescription: String? {
        description
    }
}

/// Replays legal moves and captures the SAN and numbering needed by move-list UI.
public struct ChessMoveRecordBuilder {
    private let sanSerializer: SANSerializer

    /// Creates a move-record builder.
    public init(sanSerializer: SANSerializer = SANSerializer()) {
        self.sanSerializer = sanSerializer
    }

    /// Builds display-ready move records by replaying `moves` from `initialPosition`.
    ///
    /// SAN depends on the pre-move position, so callers should use this helper
    /// instead of formatting stored coordinate moves in isolation.
    ///
    /// - Parameters:
    ///   - initialPosition: Position before the first move in `moves`.
    ///   - moves: Legal moves to replay from `initialPosition`.
    /// - Returns: Display-ready move records in ply order.
    /// - Throws: `ChessMoveRecordBuilderError.illegalMove` when a move cannot
    ///   be legally applied to the replayed position.
    public func records(initialPosition: Position, moves: [Move]) throws -> [ChessMoveRecord] {
        let game = Game(position: initialPosition)
        var records: [ChessMoveRecord] = []

        for move in moves {
            let record = try record(for: move, in: game, ply: records.count + 1)
            records.append(record)
            game.apply(move: move)
        }

        return records
    }

    /// Builds one display-ready move record for the current `game` position.
    ///
    /// This is useful for apps that append records as moves are made instead of
    /// replaying a whole history.
    ///
    /// - Parameters:
    ///   - move: Legal move to describe.
    ///   - game: Game state before `move` is applied.
    ///   - ply: One-based ply index to assign to the returned record.
    /// - Returns: A display-ready move record for the pre-move position.
    /// - Throws: `ChessMoveRecordBuilderError.illegalMove` when `move` is not
    ///   legal in `game`.
    public func record(for move: Move, in game: Game, ply: Int) throws -> ChessMoveRecord {
        guard game.legalMoves.contains(move) else {
            throw ChessMoveRecordBuilderError.illegalMove(move: move, ply: ply)
        }

        return ChessMoveRecord(
            ply: ply,
            fullMoveNumber: game.position.counter.fullMoves,
            side: game.position.state.turn,
            move: move,
            san: sanSerializer.san(for: move, in: game)
        )
    }
}
