//
//  PawnMoveGenerator.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

class PawnMoveGenerator: PieceMoveGenerator {

    func moves(from square: Square, in position: Position) -> [Move] {
        let destinations = self.reachableSquares(from: square, in: position)
        return self.promotedMoves(from: square, in: position, destinations: destinations)
    }

    func reachableSquares(from square: Square, in position: Position) -> [Square] {
        return self.oneSquareMoves(from: square, in: position)
            + self.twoSquareMoves(from: square, in: position)
            + self.captureMoves(from: square, in: position)
            + self.enPassantMoves(from: square, in: position)
    }

    private func oneSquareMoves(from square: Square, in position: Position) -> [Square] {
        let direction = position.state.turn == .white ? 1 : -1
        let destination = square.translate(file: 0, rank: direction)
        if destination.isValid {
            if (position.board.bitboards.white | position.board.bitboards.black)
                & destination.bitboardMask == Int64.zero
            {
                return [destination]
            }
        }
        return []
    }

    private func twoSquareMoves(from square: Square, in position: Position) -> [Square] {
        let initialRank = position.state.turn == .white ? 1 : 6
        guard square.rank == initialRank else {
            return []
        }

        let offset = position.state.turn == .white ? 1 : -1
        let isPathClear =
            (position.board.bitboards.white | position.board.bitboards.black)
            & square.translate(file: 0, rank: offset).bitboardMask == Int64.zero
            && (position.board.bitboards.white | position.board.bitboards.black)
                & square.translate(file: 0, rank: offset * 2).bitboardMask == Int64.zero
        guard isPathClear else {
            return []
        }

        return [square.translate(file: 0, rank: offset * 2)]
    }

    private func captureMoves(from square: Square, in position: Position) -> [Square] {
        let direction = position.state.turn == .white ? 1 : -1

        var destinations = [Square]()

        for offset in MoveOffsets().pawnCaptures {
            let captureSquare = square.translate(
                file: offset.0, rank: offset.1 * direction)
            if !captureSquare.isValid {
                continue
            }
            if position.board.bitboards.bitboard(for: position.state.turn.opposite)
                & captureSquare.bitboardMask != Int64.zero
            {
                destinations.append(captureSquare)
            }
        }

        return destinations
    }

    private func enPassantMoves(from square: Square, in position: Position) -> [Square] {
        guard let enPassantSquare = position.state.enPassant else {
            return []
        }

        let direction = position.state.turn == .white ? 1 : -1

        for captureOffset in MoveOffsets().pawnCaptures {
            let captureSquare = square.translate(
                file: captureOffset.0, rank: captureOffset.1 * direction)
            if captureSquare == enPassantSquare {
                return [enPassantSquare]
            }
        }

        return []
    }

    private func promotedMoves(from square: Square, in position: Position, destinations: [Square])
        -> [Move]
    {
        let promotionRank = position.state.turn == .white ? 7 : 0
        let promotions = destinations.filter { $0.rank == promotionRank }
        let destinations = destinations.filter { $0.rank != promotionRank }

        var promotionMoves = promotions.flatMap {
            [
                "\(square)\($0)Q",
                "\(square)\($0)R",
                "\(square)\($0)B",
                "\(square)\($0)N",
            ]
        }
        if position.state.turn == .black {
            promotionMoves = promotionMoves.map { $0.lowercased() }
        }

        return destinations.map { Move(from: square, to: $0) }
            + promotionMoves.map { Move(string: $0) }
    }

}
