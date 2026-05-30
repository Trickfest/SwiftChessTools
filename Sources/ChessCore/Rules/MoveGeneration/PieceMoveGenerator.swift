//
//  PieceMoveGenerator.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

protocol PieceMoveGenerator {
    func moves(from square: Square, in position: Position) -> [Move]
    func reachableSquares(from square: Square, in position: Position) -> [Square]
}
