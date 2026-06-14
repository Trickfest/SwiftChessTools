//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// Tracks a playable game, including the current position and move history.
public class Game {

    private let rules: Rules

    /// Number of times each board position has appeared in this game.
    public private(set) var positionCounts: [Board: Int]

    /// Number of times each rules-relevant repetition key has appeared.
    public private(set) var repetitionCounts: [GameRepetitionKey: Int]

    /// Moves that produced the current position.
    public private(set) var moveHistory: [Move]

    /// Current position, including board state, side to move, and counters.
    public var position: Position

    /// `true` when the side to move is currently in check.
    public var isCheck: Bool {
        return self.rules.isCheck(in: self.position)
    }

    /// `true` when the side to move is checkmated.
    public var isCheckmate: Bool {
        return self.rules.isCheckmate(in: self.position)
    }

    /// `true` when the side to move has no legal moves and is not in check.
    public var isStalemate: Bool {
        return !self.isCheck && self.legalMoves.isEmpty
    }

    /// Current status of the game.
    public var status: GameStatus {
        let legalMoves = self.legalMoves

        if legalMoves.isEmpty {
            if self.isCheck {
                return .checkmate(winner: self.position.state.turn.opposite)
            }
            return .draw(.stalemate)
        }

        if self.hasInsufficientMaterial {
            return .draw(.insufficientMaterial)
        }

        if self.position.counter.halfMoves >= 150 {
            return .draw(.seventyFiveMoveRule)
        }

        if self.currentRepetitionCount >= 5 {
            return .draw(.fivefoldRepetition)
        }

        return .ongoing(drawClaims: self.drawClaims)
    }

    /// Final outcome if the current status has one.
    public var outcome: GameOutcome? {
        return self.status.outcome
    }

    /// `true` when the current status is an automatic draw.
    public var isDraw: Bool {
        if case .draw = self.status {
            return true
        }
        return false
    }

    /// Draw claims currently available to the player to move.
    public var drawClaims: Set<GameDrawClaim> {
        var claims = Set<GameDrawClaim>()

        if self.position.counter.halfMoves >= 100 {
            claims.insert(.fiftyMoveRule)
        }

        if self.currentRepetitionCount >= 3 {
            claims.insert(.threefoldRepetition)
        }

        return claims
    }

    /// Number of times the current repetition key has appeared.
    public var currentRepetitionCount: Int {
        let count = self.repetitionCounts[GameRepetitionKey(position: self.position), default: 0]
        return max(count, 1)
    }

    // MARK: Initialization

    init(
        position: Position,
        moves: [Move],
        positionCounts: [Board: Int],
        repetitionCounts: [GameRepetitionKey: Int]
    ) {
        self.position = position
        self.moveHistory = moves
        self.positionCounts = positionCounts
        self.repetitionCounts = repetitionCounts
        self.rules = StandardRules()
    }

    /// Creates a game from an existing position.
    ///
    /// - Parameters:
    ///   - position: Position to use as the starting point.
    ///   - moves: Moves that already led to that position.
    public init(position: Position, moves: [Move] = []) {
        let repetitionKey = GameRepetitionKey(position: position)
        self.positionCounts = [
            position.board: 1,
        ]
        self.repetitionCounts = [
            repetitionKey: 1,
        ]
        self.moveHistory = moves
        self.position = position
        self.rules = StandardRules()
    }

    /// Creates a game with a specific rule implementation.
    ///
    /// - Parameters:
    ///   - position: Position to use as the starting point.
    ///   - moves: Moves that already led to that position.
    ///   - rules: Rule set used to generate and validate moves.
    internal init(position: Position, moves: [Move] = [], rules: Rules) {
        let repetitionKey = GameRepetitionKey(position: position)
        self.positionCounts = [
            position.board: 1,
        ]
        self.repetitionCounts = [
            repetitionKey: 1,
        ]
        self.moveHistory = moves
        self.position = position
        self.rules = rules
    }

    // MARK: Applying moves

    /// Legal moves available to the side to move.
    public var legalMoves: [Move] {
        return self.rules.legalMoves(in: self.position)
    }

    /// Applies a coordinate move string such as `"e2e4"` or `"e7e8Q"`.
    ///
    /// This method assumes the move is legal. Check `legalMoves` first when
    /// accepting input from a user or engine.
    ///
    /// - Throws: `MoveParsingError` when `coordinateMove` is malformed.
    public func apply(move coordinateMove: String) throws {
        let move = try Move(string: coordinateMove)
        self.apply(move: move)
    }

    /// Applies a move to the current position.
    ///
    /// This method assumes the move is legal. Check `legalMoves` first when
    /// accepting input from a user or engine.
    public func apply(move: Move) {
        self.moveHistory.append(move)

        let enPassant = self.enPassantTarget(after: move)

        self.updateMoveCounters(after: move)
        self.updateCastlingRights(after: move)
        self.applyBoardMove(move)

        self.position.state.enPassant = enPassant
        self.toggleTurn()

        if self.positionCounts[self.position.board] == nil {
            self.positionCounts[self.position.board] = 0
        }
        self.positionCounts[self.position.board]! += 1

        let repetitionKey = GameRepetitionKey(position: self.position)
        if self.repetitionCounts[repetitionKey] == nil {
            self.repetitionCounts[repetitionKey] = 0
        }
        self.repetitionCounts[repetitionKey]! += 1
    }

    private func applyBoardMove(_ move: Move) {
        let isCastling =
            position.board.bitboards.king & move.from.bitboardMask != Int64.zero
            && abs(move.from.file - move.to.file) > 1

        let isEnPassant =
            position.board.bitboards.pawn & move.from.bitboardMask != Int64.zero
            && move.to == self.position.state.enPassant

        let isPawnPromotion = move.promotion != nil

        if isCastling {
            self.castle(move)
        } else if isEnPassant {
            self.captureEnPassant(move)
        } else if isPawnPromotion {
            self.promotePawn(move)
        } else {
            self.movePiece(move)
        }
    }

    private func movePiece(_ move: Move) {
        self.position.board[move.to] = self.position.board[move.from]
        self.position.board[move.from] = nil
    }

    private func castle(_ move: Move) {
        self.movePiece(move)

        let rank = self.position.state.turn == .white ? "1" : "8"

        if move.to.file == 2 {
            self.movePiece(try! Move(string: "a" + rank + "d" + rank))
        } else if move.to.file == 6 {
            self.movePiece(try! Move(string: "h" + rank + "f" + rank))
        }
    }

    private func captureEnPassant(_ move: Move) {
        self.movePiece(move)

        guard let enPassant = self.position.state.enPassant else {
            return
        }

        let rank = self.position.state.turn == .white ? 4 : 3
        self.position.board[Square(file: enPassant.file, rank: rank)] = nil
    }

    private func promotePawn(_ move: Move) {
        self.movePiece(move)

        guard let kind = move.promotion else {
            return
        }
        self.position.board[move.to] = Piece(kind: kind, color: self.position.state.turn)
    }

    private func updateMoveCounters(after move: Move) {
        let isCapture =
            position.board.bitboards.bitboard(for: position.state.turn.opposite)
            & move.to.bitboardMask != Int64.zero
        let isPawnAdvance = position.board.bitboards.pawn & move.from.bitboardMask != Int64.zero

        if isCapture || isPawnAdvance {
            self.position.counter.halfMoves = 0
        } else {
            self.position.counter.halfMoves += 1
        }

        if self.position.state.turn == .black {
            self.position.counter.fullMoves += 1
        }
    }

    private func toggleTurn() {
        self.position.state.turn = self.position.state.turn.opposite
    }

    private func enPassantTarget(after move: Move) -> Square? {
        if position.board.bitboards.pawn & move.from.bitboardMask == Int64.zero {
            return nil
        }
        guard abs(move.from.rank - move.to.rank) == 2 else {
            return nil
        }

        let rank = self.position.state.turn == .white ? 2 : 5
        return Square(file: move.from.file, rank: rank)
    }

    private func updateCastlingRights(after move: Move) {
        guard let piece = self.position.board[move.from] else {
            return
        }

        if piece.kind == .king {
            self.position.state.castlingRights = self.position.state.castlingRights
                .filter { $0.color != self.position.state.turn }
        }

        self.position.state.castlingRights = self.position.state.castlingRights.filter {
            var excludeBecauseOfFrom = false
            var excludeBecauseOfTo = false

            if let colorAndSideToExclude = castlingRightAffected(by: move.from) {
                excludeBecauseOfFrom =
                    $0.color == colorAndSideToExclude.color && $0.kind == colorAndSideToExclude.kind
            }

            if let colorAndSideToExclude = castlingRightAffected(by: move.to) {
                excludeBecauseOfTo =
                    $0.color == colorAndSideToExclude.color && $0.kind == colorAndSideToExclude.kind
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

    private var hasInsufficientMaterial: Bool {
        let pieces = self.position.board.enumeratedPieces()
        let nonKings = pieces.filter { $0.1.kind != .king }

        if nonKings.isEmpty {
            return true
        }

        if nonKings.contains(where: { [.queen, .rook, .pawn].contains($0.1.kind) }) {
            return false
        }

        let knights = nonKings.filter { $0.1.kind == .knight }
        let bishops = nonKings.filter { $0.1.kind == .bishop }

        if bishops.isEmpty && knights.count == 1 {
            return true
        }

        if knights.isEmpty && !bishops.isEmpty {
            let bishopSquareColors = Set(bishops.map { ($0.0.file + $0.0.rank).isMultiple(of: 2) })
            return bishopSquareColors.count == 1
        }

        return false
    }

    // MARK: Utilities

    /// Returns a separate game object with the same position, history, and
    /// repetition counts.
    public func copy() -> Game {
        let position = self.position
        let moves = self.moveHistory.map { $0 }

        return Game(
            position: position,
            moves: moves,
            positionCounts: self.positionCounts,
            repetitionCounts: self.repetitionCounts
        )
    }

}
