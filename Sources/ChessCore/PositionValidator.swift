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

/// A semantic issue found in a parsed chess position.
public enum PositionValidationIssue: Hashable, Sendable, CustomStringConvertible {
    /// The position is missing the king for the supplied side.
    case missingKing(PieceColor)

    /// The position has more than one king for the supplied side.
    case multipleKings(PieceColor, count: Int)

    /// A pawn appears on the first or eighth rank.
    case pawnOnInvalidRank(Square)

    /// A castling right is impossible for the current board placement.
    case invalidCastlingRight(Piece)

    /// The en-passant target is impossible for the current board placement.
    case invalidEnPassantTarget(Square)

    /// The side not to move is already in check.
    case inactiveKingInCheck(PieceColor)

    /// Human-readable issue text.
    public var description: String {
        switch self {
        case let .missingKing(color):
            return "Missing \(color) king."
        case let .multipleKings(color, count):
            return "Expected one \(color) king, found \(count)."
        case let .pawnOnInvalidRank(square):
            return "Pawn on invalid rank at \(square)."
        case let .invalidCastlingRight(right):
            return "Invalid castling right: \(right)."
        case let .invalidEnPassantTarget(square):
            return "Invalid en passant target: \(square)."
        case let .inactiveKingInCheck(color):
            return "\(color) is not to move but is in check."
        }
    }
}

/// Error thrown when strict semantic position validation fails.
public enum PositionValidationError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// The position failed semantic validation with one or more issues.
    case invalidPosition([PositionValidationIssue])

    /// Human-readable error text.
    public var description: String {
        switch self {
        case let .invalidPosition(issues):
            let issueText = issues.map(\.description).joined(separator: " ")
            return "Invalid chess position: \(issueText)"
        }
    }

    /// Localized validation failure text.
    public var errorDescription: String? {
        description
    }
}

/// Result of semantically validating a parsed chess position.
///
/// This result preserves the parsed position even when issues are present, so
/// editors can display or repair an invalid position without reparsing input.
public struct PositionValidationResult: Equatable, Sendable {

    /// The position that was checked.
    public let position: Position

    /// Semantic issues found in the position.
    public let issues: [PositionValidationIssue]

    /// Creates a validation result for a parsed position.
    public init(position: Position, issues: [PositionValidationIssue]) {
        self.position = position
        self.issues = issues
    }

    /// `true` when no semantic validation issues were found.
    public var isValid: Bool {
        issues.isEmpty
    }

    /// Returns `position`, or throws the same error as strict validation.
    public func validatedPosition() throws -> Position {
        guard isValid else {
            throw PositionValidationError.invalidPosition(issues)
        }
        return position
    }

}

/// Performs semantic validation for parsed chess positions.
///
/// `PositionValidator` assumes FEN syntax has already been parsed into a
/// `Position`. It checks standard-position constraints that are not expressible
/// in the FEN grammar itself.
///
/// ```swift
/// let position = try FENSerializer().position(from: fen)
/// let result = PositionValidator().validationResult(for: position)
/// if !result.isValid {
///     print(result.issues)
/// }
/// ```
public struct PositionValidator: Sendable {

    /// Creates a position validator.
    public init() {}

    /// Returns semantic issues found in `position`.
    ///
    /// The returned array is empty when the position passes all semantic
    /// validation checks.
    public func issues(in position: Position) -> [PositionValidationIssue] {
        var issues: [PositionValidationIssue] = []
        let pieces = position.board.enumeratedPieces()

        for color in [PieceColor.white, .black] {
            let kingCount = pieces.filter { $0.1 == Piece(kind: .king, color: color) }.count
            if kingCount == 0 {
                issues.append(.missingKing(color))
            } else if kingCount > 1 {
                issues.append(.multipleKings(color, count: kingCount))
            }
        }

        issues += pieces
            .filter { $0.1.kind == .pawn && ($0.0.rank == 0 || $0.0.rank == 7) }
            .map { .pawnOnInvalidRank($0.0) }

        for right in position.state.castlingRights
            where !self.isValidCastlingRight(right, in: position)
        {
            issues.append(.invalidCastlingRight(right))
        }

        if let enPassant = position.state.enPassant,
           !self.isValidEnPassantTarget(enPassant, in: position)
        {
            issues.append(.invalidEnPassantTarget(enPassant))
        }

        var inactiveTurnPosition = position
        inactiveTurnPosition.state.turn = position.state.turn.opposite
        if StandardRules().isCheck(in: inactiveTurnPosition) {
            issues.append(.inactiveKingInCheck(position.state.turn.opposite))
        }

        return issues
    }

    /// Returns a semantic validation result for `position`.
    public func validationResult(for position: Position) -> PositionValidationResult {
        PositionValidationResult(position: position, issues: self.issues(in: position))
    }

    /// Throws when `position` has semantic validation issues.
    ///
    /// Use this strict API when invalid positions should fail fast. Use
    /// `validationResult(for:)` when you need structured diagnostics.
    public func validate(_ position: Position) throws {
        _ = try self.validationResult(for: position).validatedPosition()
    }

    private func isValidCastlingRight(_ right: Piece, in position: Position) -> Bool {
        let rank = right.color == .white ? 0 : 7
        let kingSquare = Square(file: 4, rank: rank)
        let rookFile: Int

        switch right.kind {
        case .king:
            rookFile = 7
        case .queen:
            rookFile = 0
        default:
            return false
        }

        let rookSquare = Square(file: rookFile, rank: rank)
        return position.board[kingSquare] == Piece(kind: .king, color: right.color)
            && position.board[rookSquare] == Piece(kind: .rook, color: right.color)
    }

    private func isValidEnPassantTarget(_ target: Square, in position: Position) -> Bool {
        guard position.counter.halfMoves == 0 else {
            return false
        }

        guard position.board[target] == nil else {
            return false
        }

        let sourceRank = position.state.turn == .white ? target.rank - 1 : target.rank + 1
        guard (0..<8).contains(sourceRank) else {
            return false
        }

        let capturedSquare = Square(file: target.file, rank: sourceRank)
        guard position.board[capturedSquare] == Piece(kind: .pawn, color: position.state.turn.opposite)
        else {
            return false
        }

        for fileOffset in [-1, 1] {
            let source = Square(file: target.file + fileOffset, rank: sourceRank)
            guard source.isValid else {
                continue
            }
            guard position.board[source] == Piece(kind: .pawn, color: position.state.turn) else {
                continue
            }
            if StandardRules().legalMovesForPiece(at: source, in: position)
                .contains(Move(from: source, to: target))
            {
                return true
            }
        }

        return false
    }

}
