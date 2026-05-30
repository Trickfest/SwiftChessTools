//
//  Move.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// A move from one square to another, with an optional promotion piece.
public struct Move: CustomStringConvertible, Hashable {

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
    public init(string: String) {
        let fromIndex = string.index(string.startIndex, offsetBy: 2)
        let fromString = string[..<fromIndex].description
        self.from = Square(coordinate: fromString)

        let toIndex = string.index(string.startIndex, offsetBy: 4)
        let toString = string[fromIndex..<toIndex].description
        self.to = Square(coordinate: toString)

        if let promotionCharacter = string.last {
            self.promotion = Piece(character: promotionCharacter)?.kind
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
