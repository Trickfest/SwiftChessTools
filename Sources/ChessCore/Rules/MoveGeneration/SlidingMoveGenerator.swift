//
//  SlidingMoveGenerator.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

class SlidingMoveGenerator: RangeMoveGenerator {

    private let offsets: [(Int, Int)]

    init(offsets: [(Int, Int)]) {
        self.offsets = offsets
    }

    func reachableSquares(from square: Square, in position: Position) -> [Square] {
        self.offsets
            .flatMap { self.process(offset: $0, for: square, in: position) }
    }

    private func process(offset: (Int, Int), for square: Square, in position: Position)
        -> [Square]
    {
        var destinations = [Square]()

        for distance in 1..<8 {
            let destination = square.translate(
                file: offset.0 * distance, rank: offset.1 * distance)
            if !destination.isValid {
                break
            }

            // A friendly piece blocks the ray and cannot be captured.
            if position.board.bitboards.bitboard(for: position.state.turn)
                & destination.bitboardMask != UInt64.zero
            {
                break
            }

            // An enemy piece is a valid destination, then the ray stops.
            if position.board.bitboards.bitboard(for: position.state.turn.opposite)
                & destination.bitboardMask != UInt64.zero
            {
                destinations.append(destination)
                break
            }
            destinations.append(destination)
        }

        return destinations
    }

}
