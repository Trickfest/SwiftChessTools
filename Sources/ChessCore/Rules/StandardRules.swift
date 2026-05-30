//
//  StandardRules.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// Standard chess rules for legal move generation and check detection.
public class StandardRules: Rules {

    private let rays = Rays()
    private let moveGenerators: [PieceKind: PieceMoveGenerator]

    /// Creates the standard rule set.
    public init() {
        self.moveGenerators = [
            .king: KingMoveGenerator(),
            .queen: QueenMoveGenerator(),
            .rook: RookMoveGenerator(),
            .bishop: BishopMoveGenerator(),
            .knight: KnightMoveGenerator(),
            .pawn: PawnMoveGenerator(),
        ]
    }

    func isCheck(in position: Position) -> Bool {
        guard let kingSquare = self.kingSquare(in: position, color: position.state.turn) else {
            return false
        }

        let moveOffsets = MoveOffsets()
        let bitboards = position.board.bitboards

        if self.hasSlidingAttack(
            kingSquare: kingSquare,
            turn: position.state.turn,
            offsets: moveOffsets.diagonal,
            bitboards: bitboards,
            pieces: bitboards.queen | bitboards.bishop)
        {
            return true
        }

        let kingRays: Bitboard! = self.rays.orthogonal[kingSquare.bitboardMask]

        if (kingRays & (bitboards.rook | bitboards.queen)
            & bitboards.bitboard(for: position.state.turn.opposite) != Bitboard.zero)
            && self.hasSlidingAttack(
                kingSquare: kingSquare,
                turn: position.state.turn,
                offsets: moveOffsets.orthogonal,
                bitboards: bitboards,
                pieces: bitboards.queen | bitboards.rook)
        {
            return true
        }

        for offset in moveOffsets.knight {
            let destination = kingSquare.translate(file: offset.0, rank: offset.1)
            guard destination.isValid else {
                continue
            }
            if bitboards.bitboard(for: position.state.turn.opposite) & bitboards.knight
                & destination.bitboardMask != Int64.zero
            {
                return true
            }
        }

        for offset in moveOffsets.pawnCaptures {
            let sign = position.state.turn == .white ? 1 : -1
            let destination = kingSquare.translate(file: offset.0, rank: offset.1 * sign)
            guard destination.isValid else {
                continue
            }
            if bitboards.pawn & bitboards.bitboard(for: position.state.turn.opposite)
                & destination.bitboardMask != Int64.zero
            {
                return true
            }
        }

        return false
    }

    private func hasSlidingAttack(
        kingSquare: Square,
        turn: PieceColor,
        offsets: [(Int, Int)],
        bitboards: Bitboards,
        pieces: Bitboard
    ) -> Bool {
        for offset in offsets {
            for distance in 1..<8 {
                let destination = kingSquare.translate(
                    file: offset.0 * distance,
                    rank: offset.1 * distance)
                guard destination.isValid else {
                    break
                }
                if bitboards.bitboard(for: turn) & destination.bitboardMask != Int64.zero {
                    break
                }

                if (bitboards.white | bitboards.black) & destination.bitboardMask == Int64.zero {
                    continue
                }

                if pieces & destination.bitboardMask != Int64.zero {
                    return true
                } else {
                    break
                }
            }
        }

        return false
    }

    func isCheckmate(in position: Position) -> Bool {
        guard self.isCheck(in: position) else {
            return false
        }
        return Game(position: position).legalMoves.isEmpty
    }

    func legalMoves(in position: Position) -> [Move] {
        return self.piecesForSideToMove(in: position)
            .flatMap { self.legalMovesForPiece(at: $0.0, in: position) }
    }

    /// Returns legal moves for the piece on `square`.
    public func legalMovesForPiece(at square: Square, in position: Position) -> [Move] {
        guard let piece = position.board[square] else {
            return []
        }
        guard piece.color == position.state.turn else {
            return []
        }
        guard let moveGenerator = self.moveGenerators[piece.kind] else {
            return []
        }

        let moves = moveGenerator.moves(from: square, in: position)
        return self.filterIllegal(moves: moves, for: position)
    }

    public func reachableSquares(in position: Position) -> [Square] {
        return self.piecesForSideToMove(in: position)
            .filter { $0.1.kind != .king }
            .flatMap { self.reachableSquaresForPiece(at: $0.0, in: position) }
    }

    private func reachableSquaresForPiece(at square: Square, in position: Position) -> [Square] {
        guard let piece = position.board[square] else {
            return []
        }
        guard piece.color == position.state.turn else {
            return []
        }
        guard let moveGenerator = self.moveGenerators[piece.kind] else {
            return []
        }
        if moveGenerator is KingMoveGenerator {
            return []
        }

        return moveGenerator.reachableSquares(from: square, in: position)
    }

    private func filterIllegal(moves: [Move], for position: Position) -> [Move] {
        let filter = { (move: Move) -> Bool in
            var nextPosition = position
            nextPosition.board[move.to] = nextPosition.board[move.from]
            nextPosition.board[move.from] = nil

            // En passant captures remove a pawn from a square the moving pawn
            // never lands on, so simulate that before checking king safety.
            if let enPassantCapturedPawn = self.capturedEnPassantPawnSquare(
                move: move, position: position)
            {
                nextPosition.board[enPassantCapturedPawn] = nil
            }

            if self.isIllegalCastling(move: move, position: position) {
                return false
            }

            return !self.isCheck(in: nextPosition)
        }

        return moves.filter(filter)
    }

    private func capturedEnPassantPawnSquare(move: Move, position: Position) -> Square? {
        guard let enPassant = position.state.enPassant else {
            return nil
        }
        if move.to.file == enPassant.file && move.to.rank == enPassant.rank {
            return Square(file: enPassant.file, rank: enPassant.rank == 2 ? 3 : 4)
        }
        return nil
    }

    private func piecesForSideToMove(in position: Position) -> [(Square, Piece)] {
        return position.board.enumeratedPieces()
            .filter { $0.1.color == position.state.turn }
    }

    private func kingSquare(in position: Position, color: PieceColor) -> Square? {
        let mask = position.board.bitboards.king & position.board.bitboards.bitboard(for: color)
        let square = Square(bitboardMask: mask)
        return square.isValid ? square : nil
    }

    private func isIllegalCastling(move: Move, position: Position) -> Bool {
        guard position.board.bitboards.king & move.from.bitboardMask != Int64.zero else {
            return false
        }
        guard abs(move.from.file - move.to.file) > 1 else {
            return false
        }
        if self.isCastlingFromCheck(move: move, position: position) {
            return true
        }
        if self.isCastlingThroughCheck(move: move, position: position) {
            return true
        }
        return false
    }

    private func isCastlingThroughCheck(move: Move, position: Position) -> Bool {
        let fileOffset = (move.to.file - move.from.file) / 2
        let squareBetween = move.from.translate(file: fileOffset, rank: 0)

        var nextPosition = position
        nextPosition.board[squareBetween] = nextPosition.board[move.from]
        nextPosition.board[move.from] = nil
        nextPosition.state.turn = nextPosition.state.turn.opposite

        if self.reachableSquares(in: nextPosition).contains(squareBetween) {
            return true
        }

        return false
    }

    private func isCastlingFromCheck(move: Move, position: Position) -> Bool {
        var nextPosition = position
        nextPosition.state.turn = nextPosition.state.turn.opposite
        if self.reachableSquares(in: nextPosition).contains(move.from) {
            return true
        }
        return false
    }

}
