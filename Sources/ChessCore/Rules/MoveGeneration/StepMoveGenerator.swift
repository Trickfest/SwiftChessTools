//
//  StepMoveGenerator.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

class StepMoveGenerator: RangeMoveGenerator {

    private let offsets: [(Int, Int)]

    init(offsets: [(Int, Int)]) {
        self.offsets = offsets
    }

    func reachableSquares(from square: Square, in position: Position) -> [Square] {
        return self.offsets
            .map { square.translate(file: $0.0, rank: $0.1) }
            .filter {
                $0.isValid
                    && position.board.bitboards.bitboard(for: position.state.turn) & $0.bitboardMask
                        == 0
            }
    }

}
