//
//  Position.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// Complete board state for a single point in a game.
public struct Position: Hashable {

    /// State that belongs to a position but is not stored directly on the board.
    public struct State: Hashable {
        /// Side to move.
        public var turn: PieceColor

        /// Castling rights that are still available.
        public var castlingRights: [Piece]

        /// Target square for a legal en passant capture.
        public var enPassant: Square?

    }

    /// Move counters stored in FEN.
    public struct Counter: Hashable {
        /// Half-moves since the last capture or pawn advance.
        public var halfMoves: Int

        /// Full-move number, starting at 1 and incrementing after Black moves.
        public var fullMoves: Int
    }

    /// Pieces on the board.
    public var board: Board

    /// Side to move, castling rights, and en passant target.
    public var state: State

    /// Half-move and full-move counters.
    public var counter: Counter

}
