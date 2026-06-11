//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation

/// Errors thrown while parsing Standard Algebraic Notation.
public enum SANParsingError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case emptySAN
    case noMatchingLegalMove(String)
    case ambiguousSAN(String)

    public var description: String {
        switch self {
        case .emptySAN:
            return "SAN string is empty."
        case let .noMatchingLegalMove(value):
            return "No legal move matches SAN: \(value)."
        case let .ambiguousSAN(value):
            return "SAN matches more than one legal move: \(value)."
        }
    }

    public var errorDescription: String? {
        description
    }
}

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
    /// - Throws: `SANParsingError` when `san` does not describe exactly one
    ///   legal move in `game`.
    public func move(for san: String, in game: Game) throws -> Move {
        let normalizedSAN = self.normalizedSAN(san)
        guard !normalizedSAN.isEmpty else {
            throw SANParsingError.emptySAN
        }

        let matches = game.legalMoves.filter {
            self.normalizedSAN(self.san(for: $0, in: game)) == normalizedSAN
        }

        if matches.count == 1, let move = matches.first {
            return move
        } else if matches.isEmpty {
            throw SANParsingError.noMatchingLegalMove(san)
        } else {
            throw SANParsingError.ambiguousSAN(san)
        }
    }

    private func normalizedSAN(_ san: String) -> String {
        san
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0", with: "O")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
    }

}
