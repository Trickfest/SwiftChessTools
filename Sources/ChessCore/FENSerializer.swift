//
//  FENSerializer.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// Converts between `Position` values and Forsyth-Edwards Notation.
public class FENSerializer {

    /// Creates a FEN serializer.
    public init() {}

    /// Parses a FEN string into a `Position`.
    ///
    /// - Parameter fen: A full six-field FEN string.
    /// - Returns: The position described by the FEN string.
    public func position(from fen: String) -> Position {
        let parts = fen.split(separator: " ")

        let state = Position.State(
            turn: self.turn(from: parts[1]),
            castlingRights: self.castlingRights(from: parts[2]),
            enPassant: self.enPassant(from: parts[3]))

        let counter = Position.Counter(
            halfMoves: self.moveCount(from: parts[4]),
            fullMoves: self.moveCount(from: parts[5]))

        return Position(
            board: self.board(from: parts[0]),
            state: state,
            counter: counter)
    }

    /// Formats a position as a full six-field FEN string.
    ///
    /// - Parameter position: The position to serialize.
    /// - Returns: A FEN string describing `position`.
    public func fen(from position: Position) -> String {
        let board = self.piecePlacement(from: position.board)
        let turn = position.state.turn == .white ? "w" : "b"

        var castlingRights = position.state.castlingRights
            .map { "\($0)" }
            .reduce("") { $0 + $1 }
        if castlingRights == "" {
            castlingRights = "-"
        }

        let enPassant = position.state.enPassant != nil ? "\(position.state.enPassant!)" : "-"

        let halfMoveClock = "\(position.counter.halfMoves)"
        let fullMoveNumber = "\(position.counter.fullMoves)"

        return [board, turn, castlingRights, enPassant, halfMoveClock, fullMoveNumber]
            .joined(separator: " ")
    }

    // MARK: Serialization

    private func piecePlacement(from board: Board) -> String {
        var ranks: [String] = []

        for rank in (0...7).reversed() {
            var emptySquares = 0
            var rankString = ""

            for file in 0...7 {
                let square = Square(file: file, rank: rank)

                if let piece = board[square] {
                    if emptySquares > 0 {
                        rankString += "\(emptySquares)"
                        emptySquares = 0
                    }
                    rankString += "\(piece)"
                } else {
                    emptySquares += 1
                }
            }

            if emptySquares > 0 {
                rankString += "\(emptySquares)"
            }

            ranks.append(rankString)
        }

        return ranks.joined(separator: "/")
    }

    // MARK: Deserialization

    private func board(from sequence: String.SubSequence) -> Board {
        var board = Board()
        var square = Square(file: 0, rank: 7)

        for c in sequence {
            if let piece = Piece(character: c) {
                board[square] = piece
                square = square.translate(file: 1, rank: 0)
            } else if c == "/" {
                square = Square(file: 0, rank: square.rank - 1)
            } else if let n = c.wholeNumberValue {
                square = square.translate(file: n, rank: 0)
            } else {
                preconditionFailure("Could not parse piece placement from FEN string.")
            }
        }

        return board
    }

    private func turn(from sequence: String.SubSequence) -> PieceColor {
        return sequence.lowercased() == "b" ? .black : .white
    }

    private func castlingRights(from sequence: String.SubSequence) -> [Piece] {
        if sequence == "-" {
            return []
        }
        return sequence.map { Piece(character: $0)! }
    }

    private func enPassant(from sequence: String.SubSequence) -> Square? {
        return sequence == "-" ? nil : Square(coordinate: String(sequence))
    }

    private func moveCount(from sequence: String.SubSequence) -> Int {
        guard let count = Int(String(sequence)) else {
            preconditionFailure("Could not parse move count from FEN field.")
        }
        return count
    }

}
