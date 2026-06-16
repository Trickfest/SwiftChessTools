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
    public private(set) var position: Position

    /// Draw claim that has been made for this game, if any.
    public private(set) var claimedDraw: GameDrawClaim?

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
        if let terminalStatus {
            return terminalStatus
        }

        if let claimedDraw {
            return .draw(claimedDraw.drawReason)
        }

        return .ongoing(drawClaims: self.availableDrawClaims)
    }

    private var terminalStatus: GameStatus? {
        let legalMoves = self.legalMoves

        if legalMoves.isEmpty {
            if self.isCheck {
                return .checkmate(winner: self.position.state.turn.opposite)
            }
            return .draw(.stalemate)
        }

        let deadPositionAnalyzer = DeadPositionAnalyzer()
        if deadPositionAnalyzer.hasInsufficientMatingMaterial(in: self.position) {
            return .draw(.insufficientMaterial)
        }

        if deadPositionAnalyzer.isDeadPosition(self.position) {
            return .draw(.deadPosition)
        }

        if self.position.counter.halfMoves >= 150 {
            return .draw(.seventyFiveMoveRule)
        }

        if self.currentRepetitionCount >= 5 {
            return .draw(.fivefoldRepetition)
        }

        return nil
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
        guard self.claimedDraw == nil else {
            return []
        }

        guard self.terminalStatus == nil else {
            return []
        }

        return self.availableDrawClaims
    }

    private var availableDrawClaims: Set<GameDrawClaim> {
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
        repetitionCounts: [GameRepetitionKey: Int],
        claimedDraw: GameDrawClaim? = nil
    ) {
        self.position = position
        self.moveHistory = moves
        self.positionCounts = positionCounts
        self.repetitionCounts = repetitionCounts
        self.claimedDraw = claimedDraw
        self.rules = StandardRules()
    }

    /// Creates a game from an existing position.
    ///
    /// `moveHistory` is stored as metadata only. It is not replayed and does not
    /// rebuild counters, castling rights, or repetition counts. Use
    /// `Game.replay(initialPosition:moves:)` when a concrete move list should
    /// produce the game state.
    ///
    /// - Parameters:
    ///   - position: Position to use as the starting point.
    ///   - moveHistory: Historical moves already known to have led to that
    ///     position.
    public init(position: Position, moveHistory: [Move] = []) {
        let repetitionKey = GameRepetitionKey(position: position)
        self.positionCounts = [
            position.board: 1,
        ]
        self.repetitionCounts = [
            repetitionKey: 1,
        ]
        self.moveHistory = moveHistory
        self.position = position
        self.claimedDraw = nil
        self.rules = StandardRules()
    }

    /// Creates a game from the standard chess starting position.
    public convenience init() {
        self.init(position: .standard)
    }

    /// Creates a game with a specific rule implementation.
    ///
    /// - Parameters:
    ///   - position: Position to use as the starting point.
    ///   - moveHistory: Moves already known to have led to that position.
    ///   - rules: Rule set used to generate and validate moves.
    internal init(position: Position, moveHistory: [Move] = [], rules: Rules) {
        let repetitionKey = GameRepetitionKey(position: position)
        self.positionCounts = [
            position.board: 1,
        ]
        self.repetitionCounts = [
            repetitionKey: 1,
        ]
        self.moveHistory = moveHistory
        self.position = position
        self.claimedDraw = nil
        self.rules = rules
    }

    /// Replays legal moves from an initial position and returns the resulting
    /// game with rebuilt counters, history, and repetition state.
    public static func replay(initialPosition: Position, moves: [Move]) throws -> Game {
        let game = Game(position: initialPosition)

        for (offset, move) in moves.enumerated() {
            guard game.legalMoves.contains(move) else {
                throw GameReplayError.illegalMove(move: move, ply: offset + 1)
            }
            game.apply(move: move)
        }

        return game
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

    /// Parses and applies a coordinate move only if it is legal.
    ///
    /// Prefer this method for user input, engine output, imported coordinate
    /// notation, and other app-boundary data that has not already been checked
    /// against `legalMoves`.
    ///
    /// - Throws: `MoveParsingError` when `coordinateMove` is malformed, or
    ///   `GameApplyError.illegalMove` when the parsed move is not legal in the
    ///   current position.
    public func applyLegal(move coordinateMove: String) throws {
        try self.applyLegal(move: Move(string: coordinateMove))
    }

    /// Applies a move only if it is legal in the current position.
    ///
    /// Prefer this method for user input, engine output, imported coordinate
    /// notation, and other app-boundary data that has not already been checked
    /// against `legalMoves`.
    ///
    /// - Throws: `GameApplyError.illegalMove` when `move` is not legal in the
    ///   current position.
    public func applyLegal(move: Move) throws {
        guard self.legalMoves.contains(move) else {
            throw GameApplyError.illegalMove(move: move, ply: self.moveHistory.count + 1)
        }
        self.apply(move: move)
    }

    /// Applies a move to the current position.
    ///
    /// This method assumes the move is legal. Check `legalMoves` first when
    /// accepting input from a user or engine.
    public func apply(move: Move) {
        self.claimedDraw = nil
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

    /// Claims an available draw rule and marks the game as drawn.
    public func claimDraw(_ claim: GameDrawClaim) throws {
        guard self.drawClaims.contains(claim) else {
            throw GameDrawClaimError.unavailable(claim)
        }
        self.claimedDraw = claim
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

    // MARK: Utilities

    /// Replaces the current position and clears derived game history.
    public func reset(to position: Position, moveHistory: [Move] = []) {
        let repetitionKey = GameRepetitionKey(position: position)
        self.position = position
        self.moveHistory = moveHistory
        self.positionCounts = [
            position.board: 1,
        ]
        self.repetitionCounts = [
            repetitionKey: 1,
        ]
        self.claimedDraw = nil
    }

    /// Returns a separate game object with the same position, history, and
    /// repetition counts.
    public func copy() -> Game {
        let position = self.position
        let moves = self.moveHistory.map { $0 }

        return Game(
            position: position,
            moves: moves,
            positionCounts: self.positionCounts,
            repetitionCounts: self.repetitionCounts,
            claimedDraw: self.claimedDraw
        )
    }

}

private extension GameDrawClaim {
    var drawReason: GameDrawReason {
        switch self {
        case .fiftyMoveRule:
            return .fiftyMoveRule
        case .threefoldRepetition:
            return .threefoldRepetition
        }
    }
}
