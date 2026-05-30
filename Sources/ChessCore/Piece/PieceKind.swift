//
//  PieceKind.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// The type of chess piece, independent of color.
public enum PieceKind: String, CustomStringConvertible {

    /// King.
    case king = "k"

    /// Queen.
    case queen = "q"

    /// Rook.
    case rook = "r"

    /// Bishop.
    case bishop = "b"

    /// Knight.
    case knight = "n"

    /// Pawn.
    case pawn = "p"

    // MARK: CustomStringConvertible

    /// Lowercase FEN character for this kind.
    public var description: String {
        return self.rawValue
    }

}
