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

/// Errors thrown while parsing Forsyth-Edwards Notation.
public enum FENParsingError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case invalidFieldCount(expected: Int, actual: Int)
    case invalidPiecePlacement(String)
    case invalidActiveColor(String)
    case invalidCastlingRights(String)
    case invalidEnPassantSquare(String)
    case invalidHalfmoveClock(String)
    case invalidFullmoveNumber(String)

    public var description: String {
        switch self {
        case let .invalidFieldCount(expected, actual):
            return "Expected \(expected) FEN fields, found \(actual)."
        case let .invalidPiecePlacement(value):
            return "Invalid FEN piece placement: \(value)."
        case let .invalidActiveColor(value):
            return "Invalid FEN active color: \(value)."
        case let .invalidCastlingRights(value):
            return "Invalid FEN castling rights: \(value)."
        case let .invalidEnPassantSquare(value):
            return "Invalid FEN en passant square: \(value)."
        case let .invalidHalfmoveClock(value):
            return "Invalid FEN halfmove clock: \(value)."
        case let .invalidFullmoveNumber(value):
            return "Invalid FEN fullmove number: \(value)."
        }
    }

    public var errorDescription: String? {
        description
    }
}

/// Converts between `Position` values and Forsyth-Edwards Notation.
public class FENSerializer {

    /// Creates a FEN serializer.
    public init() {}

    /// Parses a FEN string into a `Position`.
    ///
    /// - Parameter fen: A full six-field FEN string.
    /// - Returns: The position described by the FEN string.
    /// - Throws: `FENParsingError` when `fen` is malformed.
    public func position(from fen: String) throws -> Position {
        let parts = fen.split(separator: " ", omittingEmptySubsequences: false)

        guard parts.count == 6 else {
            throw FENParsingError.invalidFieldCount(expected: 6, actual: parts.count)
        }

        let state = Position.State(
            turn: try self.turn(from: parts[1]),
            castlingRights: try self.castlingRights(from: parts[2]),
            enPassant: try self.enPassant(from: parts[3], activeColor: parts[1]))

        let counter = Position.Counter(
            halfMoves: try self.halfMoveClock(from: parts[4]),
            fullMoves: try self.fullMoveNumber(from: parts[5]))

        return Position(
            board: try self.board(from: parts[0]),
            state: state,
            counter: counter)
    }

    /// Parses and semantically validates a FEN string.
    ///
    /// This method first applies normal FEN syntax parsing, then validates
    /// playable-position constraints such as king counts, castling rights, pawn
    /// ranks, en-passant availability, and inactive-side check.
    public func validatedPosition(from fen: String) throws -> Position {
        let position = try self.position(from: fen)
        try PositionValidator().validate(position)
        return position
    }

    /// Formats a position as a full six-field FEN string.
    ///
    /// - Parameter position: The position to serialize.
    /// - Returns: A FEN string describing `position`.
    public func fen(from position: Position) -> String {
        let board = self.piecePlacement(from: position.board)
        let turn = position.state.turn == .white ? "w" : "b"

        var castlingRights = position.state.castlingRights
            .map { "\($0)" }
            .reduce("") { $0 + $1 }
        if castlingRights == "" {
            castlingRights = "-"
        }

        let enPassant = position.state.enPassant != nil ? "\(position.state.enPassant!)" : "-"

        let halfMoveClock = "\(position.counter.halfMoves)"
        let fullMoveNumber = "\(position.counter.fullMoves)"

        return [board, turn, castlingRights, enPassant, halfMoveClock, fullMoveNumber]
            .joined(separator: " ")
    }

    // MARK: Serialization

    private func piecePlacement(from board: Board) -> String {
        var ranks: [String] = []

        for rank in (0...7).reversed() {
            var emptySquares = 0
            var rankString = ""

            for file in 0...7 {
                let square = Square(file: file, rank: rank)

                if let piece = board[square] {
                    if emptySquares > 0 {
                        rankString += "\(emptySquares)"
                        emptySquares = 0
                    }
                    rankString += "\(piece)"
                } else {
                    emptySquares += 1
                }
            }

            if emptySquares > 0 {
                rankString += "\(emptySquares)"
            }

            ranks.append(rankString)
        }

        return ranks.joined(separator: "/")
    }

    // MARK: Deserialization

    private func board(from sequence: String.SubSequence) throws -> Board {
        let ranks = sequence.split(separator: "/", omittingEmptySubsequences: false)
        guard ranks.count == 8 else {
            throw FENParsingError.invalidPiecePlacement(String(sequence))
        }

        var board = Board()
        for (rankOffset, rankSequence) in ranks.enumerated() {
            let rank = 7 - rankOffset
            var file = 0
            var previousCharacterWasDigit = false

            for character in rankSequence {
                if let piece = Piece(character: character) {
                    guard file < 8 else {
                        throw FENParsingError.invalidPiecePlacement(String(sequence))
                    }
                    board[Square(file: file, rank: rank)] = piece
                    file += 1
                    previousCharacterWasDigit = false
                } else if let emptySquares = character.wholeNumberValue {
                    guard !previousCharacterWasDigit else {
                        throw FENParsingError.invalidPiecePlacement(String(sequence))
                    }
                    guard (1...8).contains(emptySquares) else {
                        throw FENParsingError.invalidPiecePlacement(String(sequence))
                    }
                    file += emptySquares
                    previousCharacterWasDigit = true
                } else {
                    throw FENParsingError.invalidPiecePlacement(String(sequence))
                }
            }

            guard file == 8 else {
                throw FENParsingError.invalidPiecePlacement(String(sequence))
            }
        }

        return board
    }

    private func turn(from sequence: String.SubSequence) throws -> PieceColor {
        switch sequence {
        case "w":
            return .white
        case "b":
            return .black
        default:
            throw FENParsingError.invalidActiveColor(String(sequence))
        }
    }

    private func castlingRights(from sequence: String.SubSequence) throws -> [Piece] {
        if sequence == "-" {
            return []
        }

        guard !sequence.isEmpty else {
            throw FENParsingError.invalidCastlingRights(String(sequence))
        }

        var seen = Set<Character>()
        var rights: [Piece] = []

        for character in sequence {
            guard "KQkq".contains(character), !seen.contains(character),
                  let piece = Piece(character: character)
            else {
                throw FENParsingError.invalidCastlingRights(String(sequence))
            }

            seen.insert(character)
            rights.append(piece)
        }

        return rights
    }

    private func enPassant(from sequence: String.SubSequence,
                           activeColor: String.SubSequence) throws -> Square? {
        if sequence == "-" {
            return nil
        }

        guard sequence.count == 2 else {
            throw FENParsingError.invalidEnPassantSquare(String(sequence))
        }

        let square = Square(coordinate: String(sequence))
        guard square.isValid else {
            throw FENParsingError.invalidEnPassantSquare(String(sequence))
        }

        if (activeColor == "w" && square.rank != 5) || (activeColor == "b" && square.rank != 2) {
            throw FENParsingError.invalidEnPassantSquare(String(sequence))
        }

        return square
    }

    private func halfMoveClock(from sequence: String.SubSequence) throws -> Int {
        guard let count = Int(String(sequence)), count >= 0 else {
            throw FENParsingError.invalidHalfmoveClock(String(sequence))
        }
        return count
    }

    private func fullMoveNumber(from sequence: String.SubSequence) throws -> Int {
        guard let count = Int(String(sequence)), count > 0 else {
            throw FENParsingError.invalidFullmoveNumber(String(sequence))
        }
        return count
    }

}
