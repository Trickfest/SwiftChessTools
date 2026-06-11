//
//  PieceColor.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// The side a piece belongs to.
public enum PieceColor: Equatable, Sendable {

    /// The white side.
    case white

    /// The black side.
    case black

    /// The other side.
    public var opposite: PieceColor {
        return self == .white ? .black : .white
    }

}
