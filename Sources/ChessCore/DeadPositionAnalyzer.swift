//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// Detects FIDE dead positions for standard chess.
///
/// A dead position is one where neither side can possibly checkmate the other
/// by any legal sequence of moves. The analyzer is intentionally conservative:
/// it reports `true` for material-only dead positions, sealed immobile
/// pawn-barrier positions, and positions that can be proved by exhaustive
/// legal-state traversal within a bounded search. Positions outside those
/// proven classes return `false`.
///
/// `Game.status` uses this analyzer for automatic dead-position draws.
public struct DeadPositionAnalyzer: Sendable {

    /// Maximum number of unique legal-state keys explored for a blocked
    /// position proof.
    public let maximumReachabilityNodes: Int

    /// Creates a dead-position analyzer.
    ///
    /// - Parameter maximumReachabilityNodes: Search budget for the bounded
    ///   reachability fallback. If this budget is exceeded, the analyzer treats
    ///   the position as not proven dead.
    public init(maximumReachabilityNodes: Int = 100_000) {
        self.maximumReachabilityNodes = maximumReachabilityNodes
    }

    /// `true` when the position is proven dead.
    ///
    /// A `false` result can mean either that checkmate is possible or that the
    /// analyzer did not prove deadness within its supported proof classes.
    public func isDeadPosition(_ position: Position) -> Bool {
        if self.hasInsufficientMatingMaterial(in: position) {
            return true
        }

        if self.hasSealedImmobilePawnBarrier(in: position) {
            return true
        }

        return self.canProveDeadByReachability(from: position)
    }

    /// `true` when neither side has enough material to produce any checkmate.
    ///
    /// This is a fast material-only subset of full dead-position analysis.
    public func hasInsufficientMatingMaterial(in position: Position) -> Bool {
        let pieces = position.board.enumeratedPieces()
        return self.hasInsufficientMatingMaterial(for: .white, pieces: pieces)
            && self.hasInsufficientMatingMaterial(for: .black, pieces: pieces)
    }

    private func hasInsufficientMatingMaterial(
        for color: PieceColor,
        pieces: [(Square, Piece)]
    ) -> Bool {
        let ownNonKings = pieces.filter { $0.1.color == color && $0.1.kind != .king }

        if ownNonKings.isEmpty {
            return true
        }

        if ownNonKings.contains(where: { [.queen, .rook, .pawn].contains($0.1.kind) }) {
            return false
        }

        let ownKnights = ownNonKings.filter { $0.1.kind == .knight }
        if !ownKnights.isEmpty {
            let ownHasOnlyOneKnight = ownNonKings.count == 1 && ownKnights.count == 1
            let opponentCanSelfBlock = pieces.contains {
                $0.1.color == color.opposite
                    && [.pawn, .knight, .bishop, .rook].contains($0.1.kind)
            }
            return ownHasOnlyOneKnight && !opponentCanSelfBlock
        }

        let ownBishops = ownNonKings.filter { $0.1.kind == .bishop }
        if !ownBishops.isEmpty {
            let allBishops = pieces.filter { $0.1.kind == .bishop }
            let bishopSquareColors = Set(allBishops.map(\.0.isLightSquare))
            let opponentCanSelfBlock = pieces.contains {
                $0.1.color == color.opposite
                    && [.pawn, .knight].contains($0.1.kind)
            }
            return bishopSquareColors.count == 1 && !opponentCanSelfBlock
        }

        return true
    }

    private func canProveDeadByReachability(from position: Position) -> Bool {
        let rules = StandardRules()
        let pieces = position.board.enumeratedPieces()
        guard self.isReachabilityProofCandidate(position, pieces: pieces, rules: rules) else {
            return false
        }

        var visited = Set<DeadPositionSearchKey>()
        var stack = [position]

        while let current = stack.popLast() {
            let key = DeadPositionSearchKey(position: current)
            guard visited.insert(key).inserted else {
                continue
            }

            if visited.count > self.maximumReachabilityNodes {
                return false
            }

            let legalMoves = rules.legalMoves(in: current)
            if legalMoves.isEmpty {
                if rules.isCheck(in: current) {
                    return false
                }
                continue
            }

            if self.hasPawnMoveOrCapture(legalMoves, in: current) {
                return false
            }

            for move in legalMoves {
                stack.append(self.position(after: move, in: current))
            }
        }

        return true
    }

    private func hasSealedImmobilePawnBarrier(in position: Position) -> Bool {
        let pieces = position.board.enumeratedPieces()
        guard pieces.contains(where: { $0.1.kind == .pawn }) else {
            return false
        }
        guard !pieces.contains(where: { $0.1.kind == .knight }) else {
            return false
        }

        let rules = StandardRules()
        guard !rules.isCheck(in: position) else {
            return false
        }
        guard !rules.isCheck(in: position.withTurn(position.state.turn.opposite)) else {
            return false
        }
        guard self.allPawnsAreImmobile(in: position, pieces: pieces, rules: rules) else {
            return false
        }

        // Any capture can alter the sealed barrier, so this structural proof
        // only accepts positions where both sides have non-capturing mobility.
        guard !self.hasCapture(rules.legalMoves(in: position), in: position) else {
            return false
        }

        let oppositeTurnPosition = position.withTurn(position.state.turn.opposite)
        guard !self.hasCapture(
            rules.legalMoves(in: oppositeTurnPosition),
            in: oppositeTurnPosition
        ) else {
            return false
        }

        let components = PawnBarrierComponents(position: position)
        guard let whiteKingComponent = components.kingComponent(for: .white),
              let blackKingComponent = components.kingComponent(for: .black),
              whiteKingComponent != blackKingComponent
        else {
            return false
        }

        for (square, piece) in pieces where piece.kind != .pawn && piece.kind != .king {
            guard let component = components.component(containing: square) else {
                continue
            }
            if piece.color == .white && component == blackKingComponent {
                return false
            }
            if piece.color == .black && component == whiteKingComponent {
                return false
            }
        }

        return true
    }

    private func allPawnsAreImmobile(
        in position: Position,
        pieces: [(Square, Piece)],
        rules: StandardRules
    ) -> Bool {
        for (square, piece) in pieces where piece.kind == .pawn {
            let pawnPosition = position.withTurn(piece.color)
            if !rules.legalMovesForPiece(at: square, in: pawnPosition).isEmpty {
                return false
            }
        }
        return true
    }

    private func isReachabilityProofCandidate(
        _ position: Position,
        pieces: [(Square, Piece)],
        rules: StandardRules
    ) -> Bool {
        guard pieces.count <= 24 else {
            return false
        }

        guard pieces.contains(where: { $0.1.kind == .pawn }) else {
            return false
        }

        // Sealed pawn barriers prove trapped major-piece cases before this
        // fallback. Unsealed major-piece endgames can create very large
        // reversible move graphs, so keep this proof path conservative.
        guard !pieces.contains(where: { $0.1.kind == .queen || $0.1.kind == .rook }) else {
            return false
        }

        let movesForSideToMove = rules.legalMoves(in: position)
        let movesForOtherSide = rules.legalMoves(in: position.withTurn(position.state.turn.opposite))

        guard movesForSideToMove.count + movesForOtherSide.count <= 80 else {
            return false
        }

        return !self.hasPawnMoveOrCapture(movesForSideToMove, in: position)
            && !self.hasPawnMoveOrCapture(
                movesForOtherSide,
                in: position.withTurn(position.state.turn.opposite)
            )
    }

    private func hasPawnMoveOrCapture(_ moves: [Move], in position: Position) -> Bool {
        return moves.contains { move in
            guard let piece = position.board[move.from] else {
                return false
            }

            if piece.kind == .pawn {
                return true
            }

            if self.isCapture(move, in: position) {
                return true
            }

            return false
        }
    }

    private func hasCapture(_ moves: [Move], in position: Position) -> Bool {
        return moves.contains { self.isCapture($0, in: position) }
    }

    private func isCapture(_ move: Move, in position: Position) -> Bool {
        if position.board[move.to] != nil {
            return true
        }

        return self.isEnPassantCapture(move, in: position)
    }

    private func isEnPassantCapture(_ move: Move, in position: Position) -> Bool {
        guard let piece = position.board[move.from], piece.kind == .pawn else {
            return false
        }
        guard position.state.enPassant == move.to else {
            return false
        }
        return move.from.file != move.to.file
    }

    private func position(after move: Move, in position: Position) -> Position {
        var next = position

        let enPassant = self.enPassantTarget(after: move, in: position)
        self.updateCastlingRights(after: move, in: position, next: &next)
        self.applyBoardMove(move, in: position, next: &next)
        next.state.enPassant = enPassant
        next.state.turn = position.state.turn.opposite

        return next
    }

    private func applyBoardMove(_ move: Move, in position: Position, next: inout Position) {
        let isCastling =
            position.board.bitboards.king & move.from.bitboardMask != Bitboard.zero
            && abs(move.from.file - move.to.file) > 1

        let isEnPassant =
            position.board.bitboards.pawn & move.from.bitboardMask != Bitboard.zero
            && move.to == position.state.enPassant

        if isCastling {
            self.movePiece(move, in: &next)
            let rank = position.state.turn == .white ? "1" : "8"
            if move.to.file == 2 {
                self.movePiece(try! Move(string: "a" + rank + "d" + rank), in: &next)
            } else if move.to.file == 6 {
                self.movePiece(try! Move(string: "h" + rank + "f" + rank), in: &next)
            }
        } else if isEnPassant {
            self.movePiece(move, in: &next)
            guard let enPassant = position.state.enPassant else {
                return
            }
            let capturedRank = position.state.turn == .white ? 4 : 3
            next.board[Square(file: enPassant.file, rank: capturedRank)] = nil
        } else if let promotion = move.promotion {
            self.movePiece(move, in: &next)
            next.board[move.to] = Piece(kind: promotion, color: position.state.turn)
        } else {
            self.movePiece(move, in: &next)
        }
    }

    private func movePiece(_ move: Move, in position: inout Position) {
        position.board[move.to] = position.board[move.from]
        position.board[move.from] = nil
    }

    private func enPassantTarget(after move: Move, in position: Position) -> Square? {
        if position.board.bitboards.pawn & move.from.bitboardMask == Bitboard.zero {
            return nil
        }
        guard abs(move.from.rank - move.to.rank) == 2 else {
            return nil
        }

        let rank = position.state.turn == .white ? 2 : 5
        return Square(file: move.from.file, rank: rank)
    }

    private func updateCastlingRights(after move: Move, in position: Position, next: inout Position) {
        guard let piece = position.board[move.from] else {
            return
        }

        if piece.kind == .king {
            next.state.castlingRights = next.state.castlingRights
                .filter { $0.color != position.state.turn }
        }

        next.state.castlingRights = next.state.castlingRights.filter {
            var excludeBecauseOfFrom = false
            var excludeBecauseOfTo = false

            if let affected = self.castlingRightAffected(by: move.from) {
                excludeBecauseOfFrom = $0.color == affected.color && $0.kind == affected.kind
            }

            if let affected = self.castlingRightAffected(by: move.to) {
                excludeBecauseOfTo = $0.color == affected.color && $0.kind == affected.kind
            }

            return !(excludeBecauseOfFrom || excludeBecauseOfTo)
        }
    }

    private func castlingRightAffected(by square: Square) -> Piece? {
        if square.file == 0 && square.rank == 0 {
            return Piece(kind: .queen, color: .white)
        }

        if square.file == 7 && square.rank == 0 {
            return Piece(kind: .king, color: .white)
        }

        if square.file == 0 && square.rank == 7 {
            return Piece(kind: .queen, color: .black)
        }

        if square.file == 7 && square.rank == 7 {
            return Piece(kind: .king, color: .black)
        }

        return nil
    }
}

private struct DeadPositionSearchKey: Hashable {
    var board: Board
    var turn: PieceColor
    var castlingRights: Set<Piece>
    var enPassant: Square?

    init(position: Position) {
        self.board = position.board
        self.turn = position.state.turn
        self.castlingRights = Set(position.state.castlingRights)
        self.enPassant = GameRepetitionKey(position: position).enPassant
    }
}

private struct PawnBarrierComponents {
    private var squareComponents = [Square: Int]()
    private var kingComponents = [PieceColor: Int]()

    init(position: Position) {
        var visited = Set<Square>()
        var nextComponent = 0

        for index in Int.zero..<Board.squaresCount {
            let square = Square(index: index)
            guard !visited.contains(square), Self.isPassable(square, in: position) else {
                continue
            }

            var stack = [square]
            while let current = stack.popLast() {
                guard !visited.contains(current), Self.isPassable(current, in: position) else {
                    continue
                }
                visited.insert(current)
                self.squareComponents[current] = nextComponent

                for neighbor in Self.neighbors(of: current) where !visited.contains(neighbor) {
                    stack.append(neighbor)
                }
            }

            nextComponent += 1
        }

        for (square, piece) in position.board.enumeratedPieces() where piece.kind == .king {
            if let component = self.squareComponents[square] {
                self.kingComponents[piece.color] = component
            }
        }
    }

    func component(containing square: Square) -> Int? {
        return self.squareComponents[square]
    }

    func kingComponent(for color: PieceColor) -> Int? {
        return self.kingComponents[color]
    }

    private static func isPassable(_ square: Square, in position: Position) -> Bool {
        return position.board[square]?.kind != .pawn
    }

    private static func neighbors(of square: Square) -> [Square] {
        var neighbors = [Square]()
        for fileOffset in -1...1 {
            for rankOffset in -1...1 {
                guard fileOffset != 0 || rankOffset != 0 else {
                    continue
                }
                let neighbor = square.translate(file: fileOffset, rank: rankOffset)
                if neighbor.isValid {
                    neighbors.append(neighbor)
                }
            }
        }
        return neighbors
    }
}

private extension Position {
    func withTurn(_ turn: PieceColor) -> Position {
        var position = self
        position.state.turn = turn
        return position
    }
}

private extension Square {
    var isLightSquare: Bool {
        return (self.file + self.rank).isMultiple(of: 2)
    }
}
