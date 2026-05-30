//
//  RangeMoveGenerator.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

protocol RangeMoveGenerator: PieceMoveGenerator {

}

extension RangeMoveGenerator {

    func moves(from square: Square, in position: Position) -> [Move] {
        return self.reachableSquares(from: square, in: position)
            .map { Move(from: square, to: $0) }
    }

}
