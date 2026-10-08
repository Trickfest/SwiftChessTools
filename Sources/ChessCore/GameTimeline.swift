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

/// Errors raised when accessing or editing a linear game timeline.
public enum GameTimelineError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// The requested position is outside `0...moveCount`.
    case invalidPly(ply: Int, moveCount: Int)

    /// The root has a negative halfmove clock or nonpositive full-move number.
    case invalidInitialCounters(halfMoves: Int, fullMoves: Int)

    /// The move is illegal at this one-based ply in the complete line.
    case illegalMove(move: Move, ply: Int)

    /// Human-readable timeline failure text.
    public var description: String {
        switch self {
        case let .invalidPly(ply, moveCount):
            "Ply \(ply) is outside the recorded line of \(moveCount) moves."
        case let .invalidInitialCounters(halfMoves, fullMoves):
            "Invalid initial counters: halfmove clock \(halfMoves), full-move number \(fullMoves)."
        case let .illegalMove(move, ply):
            "Illegal timeline move \(move) at ply \(ply)."
        }
    }

    /// Localized timeline failure text.
    public var errorDescription: String? { description }
}

/// A validated linear move history with replay-derived game state and cached SAN.
///
/// Ply zero is `initialPosition`; ply `moveCount` is the recorded line's end.
/// The consuming app owns the selected ply, editing policy, and persistence.
/// Accessing history never changes the line, and a failed edit leaves it intact.
///
/// Like `Game.replay(initialPosition:moves:)`, validation checks move legality,
/// not permission to continue a finished game. Legally replayable continuations
/// after automatic draws are supported. Apps accepting new gameplay moves
/// should separately check the authoritative game's outcome.
///
/// Repetition starts at the supplied root. Earlier history and explicit results
/// such as a claimed draw, resignation, or timeout cannot be inferred from FEN
/// and moves. Keep those results in the live Game or app-owned state.
///
/// ```swift
/// var timeline = try GameTimeline()
/// try timeline.append(Move(string: "e2e4"))
/// let startingGame = try timeline.game(atPly: 0)
/// let currentGame = try timeline.game(atPly: timeline.moveCount)
/// ```
public struct GameTimeline: Sendable {
    /// Immutable position before the first recorded move.
    public let initialPosition: Position

    /// Validated moves in chronological order.
    public private(set) var moves: [Move]

    /// Cached display records, with one-based plies relative to this root.
    public private(set) var moveRecords: [ChessMoveRecord]

    /// Number of recorded plies, also the last valid position index.
    public var moveCount: Int { moves.count }

    /// Validates the root and entire line before creating a timeline.
    ///
    /// Root validation uses `PositionValidator`, not a proof of historical
    /// reachability. Valid terminal positions may be used as roots.
    ///
    /// - Throws: `GameTimelineError.invalidInitialCounters`,
    ///   `PositionValidationError` for semantic root issues, or
    ///   `GameTimelineError.illegalMove` for an invalid move in the line.
    public init(initialPosition: Position = .standard, moves: [Move] = []) throws {
        guard initialPosition.counter.halfMoves >= 0,
              initialPosition.counter.fullMoves > 0
        else {
            throw GameTimelineError.invalidInitialCounters(
                halfMoves: initialPosition.counter.halfMoves,
                fullMoves: initialPosition.counter.fullMoves
            )
        }
        try PositionValidator().validate(initialPosition)

        let game = Game(position: initialPosition)
        let records = try Self.records(for: moves, afterPly: 0, in: game)
        self.initialPosition = initialPosition
        self.moves = moves
        self.moveRecords = records
    }

    /// Replays a prefix into a new independent Game, including repetition state.
    ///
    /// Modifying the returned Game cannot change this timeline or another
    /// returned Game. The Game has no claimed draw; available claims and
    /// automatic status are derived from the prefix. Game itself is not
    /// Sendable and should remain within the caller's isolation context.
    ///
    /// - Throws: `GameTimelineError.invalidPly` for an out-of-range index.
    public func game(atPly ply: Int) throws -> Game {
        try validate(ply: ply)
        do {
            return try Game.replay(initialPosition: initialPosition, moves: Array(moves.prefix(ply)))
        } catch let GameReplayError.illegalMove(move, ply) {
            throw GameTimelineError.illegalMove(move: move, ply: ply)
        }
    }

    /// Returns the position at a ply without exposing a mutable stored object.
    ///
    /// Position does not contain repetition history. Use `game(atPly:)` when
    /// computing status or draw claims instead of creating a Game from this value.
    ///
    /// - Throws: `GameTimelineError.invalidPly` for an out-of-range index.
    public func position(atPly ply: Int) throws -> Position {
        try game(atPly: ply).position
    }

    /// Appends one legal move and returns its display record.
    ///
    /// This always edits the recorded end, regardless of the app's selected ply.
    /// A failure leaves both moves and cached records unchanged.
    ///
    /// - Throws: `GameTimelineError.illegalMove` with the next one-based ply.
    @discardableResult
    public mutating func append(_ move: Move) throws -> ChessMoveRecord {
        let game = try game(atPly: moveCount)
        let record = try Self.record(for: move, in: game, ply: moveCount + 1)
        moves.append(move)
        moveRecords.append(record)
        return record
    }

    /// Replaces all moves after a ply, preserving the root and retained prefix.
    ///
    /// An empty replacement truncates the line. At `moveCount`, this appends
    /// the supplied sequence. Passing only the existing next move still removes
    /// all later moves; apps that want to advance along an existing continuation
    /// should change only their cursor instead.
    ///
    /// The entire replacement is validated before any stored state changes.
    /// Error plies refer to the resulting complete line, not the replacement's
    /// local offsets. No cursor or app-owned state is changed.
    ///
    /// - Throws: `GameTimelineError.invalidPly`, or
    ///   `GameTimelineError.illegalMove` for an invalid replacement move.
    public mutating func replaceContinuation(afterPly ply: Int, with moves: [Move]) throws {
        let game = try game(atPly: ply)
        let replacementRecords = try Self.records(for: moves, afterPly: ply, in: game)
        let newMoves = Array(self.moves.prefix(ply)) + moves
        let newRecords = Array(moveRecords.prefix(ply)) + replacementRecords
        self.moves = newMoves
        self.moveRecords = newRecords
    }

    private func validate(ply: Int) throws {
        guard (0...moveCount).contains(ply) else {
            throw GameTimelineError.invalidPly(ply: ply, moveCount: moveCount)
        }
    }

    private static func records(for moves: [Move], afterPly ply: Int, in game: Game) throws -> [ChessMoveRecord] {
        var records: [ChessMoveRecord] = []
        records.reserveCapacity(moves.count)
        for (offset, move) in moves.enumerated() {
            records.append(try record(for: move, in: game, ply: ply + offset + 1))
            game.apply(move: move)
        }
        return records
    }

    private static func record(for move: Move, in game: Game, ply: Int) throws -> ChessMoveRecord {
        do {
            return try ChessMoveRecordBuilder().record(for: move, in: game, ply: ply)
        } catch let ChessMoveRecordBuilderError.illegalMove(move, ply) {
            throw GameTimelineError.illegalMove(move: move, ply: ply)
        }
    }
}
