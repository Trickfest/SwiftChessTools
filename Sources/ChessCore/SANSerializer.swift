//
//  SANSerializer.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2021.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2021-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Foundation

/// Converts moves to and from Standard Algebraic Notation.
public class SANSerializer {

    private let kingSideCastleSAN = "O-O"
    private let queenSideCastleSAN = "O-O-O"

    /// Creates a SAN serializer.
    public init() {}

    // MARK: - Serialization

    /// Formats a legal move as SAN in the context of a game.
    ///
    /// - Parameters:
    ///   - move: Move to serialize.
    ///   - game: Game state before `move` is applied.
    /// - Returns: SAN text describing `move`.
    public func san(for move: Move, in game: Game) -> String {
        switch game.position.board[move.from]?.kind {
        case .none:
            return ""
        case .pawn:
            return self.sanForPawnMove(move, in: game)
        case .king:
            return self.sanForKingMove(move, in: game)
        default:
            return self.sanForPieceMove(move, in: game)
        }
    }

    private func sanForPawnMove(_ move: Move, in game: Game) -> String {
        let targetSquare = game.position.board[move.to]
        var san =
            targetSquare?.kind != nil
            ? "\(move.from.coordinate.first!)x\(move.to)" : move.to.coordinate
        if let promotion = move.promotion {
            san += "=\(promotion)".uppercased()
        }
        return self.appendingCheckSuffix(to: san, after: move, in: game)
    }

    private func sanForKingMove(_ move: Move, in game: Game) -> String {
        if move.from.file == 4 {
            if move.to.file == 6 {
                return self.appendingCheckSuffix(to: kingSideCastleSAN, after: move, in: game)
            } else if move.to.file == 2 {
                return self.appendingCheckSuffix(to: queenSideCastleSAN, after: move, in: game)
            }
        }
        return self.sanForPieceMove(move, in: game)
    }

    private func sanForPieceMove(_ move: Move, in game: Game) -> String {
        let sourceSquare = game.position.board[move.from]!
        let targetSquare = game.position.board[move.to]

        var san = sourceSquare.kind.description.uppercased()

        let candidates = game.legalMoves
            .filter { $0.to == move.to && $0 != move }
            .filter { game.position.board[$0.from]?.kind == sourceSquare.kind }

        if !candidates.filter({ $0.from.file == move.from.file }).isEmpty {
            san.append(move.from.coordinate.last!)
        } else if !candidates.filter({ $0.from.rank == move.from.rank }).isEmpty {
            san.append(move.from.coordinate.first!)
        } else if !candidates.isEmpty {
            san.append(move.from.coordinate.first!)
        }

        if targetSquare != nil {
            san.append("x")
        }

        san.append(move.to.coordinate)

        return self.appendingCheckSuffix(to: san, after: move, in: game)
    }

    private func appendingCheckSuffix(to san: String, after move: Move, in game: Game) -> String {
        let gameCopy = game.copy()
        gameCopy.apply(move: move)
        if gameCopy.isCheckmate {
            return san + "#"
        } else if gameCopy.isCheck {
            return san + "+"
        }
        return san
    }

    // MARK: - Deserialization

    /// Parses SAN into the matching move for the current game state.
    ///
    /// - Parameters:
    ///   - san: SAN text such as `"Nf3"`, `"exd5"`, or `"O-O"`.
    ///   - game: Game state before the SAN move is applied.
    /// - Returns: The move represented by `san`.
    public func move(for san: String, in game: Game) -> Move {
        let promotion = self.promotion(in: san)

        let san =
            san
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "=[QRBN]", with: "", options: .regularExpression)

        if [kingSideCastleSAN, queenSideCastleSAN].contains(san) {
            return self.moveForCastlingSAN(san, in: game)
        } else if san.count == 2 {
            return self.pawnMove(for: san, promotion: promotion, in: game)
        } else {
            return self.pieceMove(for: san, promotion: promotion, in: game)
        }
    }

    private func promotion(in san: String) -> PieceKind? {
        if let range = san.range(of: "=[QRBN]", options: .regularExpression) {
            let piece = san[range]
                .replacingOccurrences(of: "=", with: "")
                .lowercased()
            return PieceKind(rawValue: piece)
        }
        return nil
    }

    private func moveForCastlingSAN(_ san: String, in game: Game) -> Move {
        let file = san == kingSideCastleSAN ? "g" : "c"
        let rank = game.position.state.turn == .white ? "1" : "8"
        return Move(string: "e\(rank)\(file)\(rank)")
    }

    private func pawnMove(for san: String, promotion: PieceKind?, in game: Game) -> Move {
        let move = game.legalMoves
            .filter { $0.to.description == san }
            .filter { game.position.board[$0.from]?.kind == .pawn }
            .first!
        return Move(from: move.from, to: move.to, promotion: promotion)
    }

    private func pieceMove(for san: String, promotion: PieceKind?, in game: Game) -> Move {
        var targetCoordinate = ""
        var remainingSAN = san.replacingOccurrences(of: "x", with: "")

        targetCoordinate += "\(remainingSAN.popLast()!)"
        targetCoordinate = "\(remainingSAN.popLast()!)" + targetCoordinate

        var pieceKind: PieceKind? = nil
        if remainingSAN.first!.isUppercase {
            pieceKind = PieceKind(rawValue: "\(remainingSAN.lowercased().first!)")
        }

        if pieceKind == nil {
            let move = game.legalMoves
                .filter({ $0.to.description == targetCoordinate })
                .filter({ game.position.board[$0.from]?.kind == .pawn })
                .filter({ $0.from.description.contains(remainingSAN) })
                .first!
            return Move(from: move.from, to: move.to, promotion: promotion)
        }

        remainingSAN = "\(remainingSAN.dropFirst())"

        var candidates = game.legalMoves
            .filter { game.position.board[$0.from]?.kind == pieceKind }
            .filter { $0.to.description == targetCoordinate }

        if !remainingSAN.isEmpty {
            candidates =
                candidates
                .filter { $0.from.description.contains(remainingSAN) }
        }

        let move = candidates.first!.from.description + targetCoordinate

        return Move(string: move)
    }

}
