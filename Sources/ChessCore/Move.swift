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

/// Errors thrown while parsing coordinate move notation.
public enum MoveParsingError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// The move text was not four coordinate characters plus an optional promotion piece.
    case invalidLength(String)

    /// The source square text is not a valid board coordinate.
    case invalidSourceSquare(String)

    /// The destination square text is not a valid board coordinate.
    case invalidDestinationSquare(String)

    /// The promotion suffix is not a valid promotion piece.
    case invalidPromotion(String)

    /// Human-readable parsing failure text.
    public var description: String {
        switch self {
        case let .invalidLength(value):
            return "Move must use four coordinate characters plus an optional promotion piece: \(value)."
        case let .invalidSourceSquare(value):
            return "Invalid move source square: \(value)."
        case let .invalidDestinationSquare(value):
            return "Invalid move destination square: \(value)."
        case let .invalidPromotion(value):
            return "Invalid promotion piece: \(value)."
        }
    }

    /// Localized parsing failure text.
    public var errorDescription: String? {
        description
    }
}

/// A move from one square to another, with an optional promotion piece.
public struct Move: CustomStringConvertible, Hashable, Sendable {

    /// Source square.
    public let from: Square

    /// Destination square.
    public let to: Square

    /// Piece kind used when this move promotes a pawn.
    public let promotion: PieceKind?

    // MARK: Initialization

    /// Creates a move from source and destination squares.
    public init(from: Square, to: Square, promotion: PieceKind? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }

    /// Creates a move from coordinate notation such as `"g1f3"` or `"e7e8Q"`.
    ///
    /// - Throws: `MoveParsingError` when `string` is not valid coordinate move
    ///   notation.
    public init(string: String) throws {
        guard string.count == 4 || string.count == 5 else {
            throw MoveParsingError.invalidLength(string)
        }

        let fromIndex = string.index(string.startIndex, offsetBy: 2)
        let fromString = string[..<fromIndex].description
        let from = Square(coordinate: fromString)
        guard from.isValid else {
            throw MoveParsingError.invalidSourceSquare(fromString)
        }

        let toIndex = string.index(string.startIndex, offsetBy: 4)
        let toString = string[fromIndex..<toIndex].description
        let to = Square(coordinate: toString)
        guard to.isValid else {
            throw MoveParsingError.invalidDestinationSquare(toString)
        }

        self.from = from
        self.to = to

        if string.count == 5, let promotionCharacter = string.last {
            let normalizedPromotionCharacter = Character(promotionCharacter.lowercased())
            guard let promotion = PieceKind(rawValue: String(normalizedPromotionCharacter)),
                  [.queen, .rook, .bishop, .knight].contains(promotion)
            else {
                throw MoveParsingError.invalidPromotion(String(promotionCharacter))
            }
            self.promotion = promotion
        } else {
            self.promotion = nil
        }
    }

    // MARK: CustomStringConvertible

    /// Coordinate notation for this move.
    public var description: String {
        var result = "\(self.from)\(self.to)"

        if let promotion = self.promotion {
            result += "\(promotion)"
        }

        return result
    }

}
