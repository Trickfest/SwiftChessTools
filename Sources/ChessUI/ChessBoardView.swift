//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

import ChessCore

/// FEN for an empty board with White to move.
public let emptyFEN = "8/8/8/8/8/8/8/8 w - - 0 1"

/// FEN for the standard chess starting position.
public let initialFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

/// Move attempt emitted by `ChessBoardView`.
///
/// The attempt describes user intent. ChessUI does not apply the move for you;
/// the app decides whether to update its game state, request promotion, show an
/// error, or ignore the attempt.
public struct ChessBoardMoveAttempt: Equatable, Sendable {
    /// Coordinate move represented by the gesture or promotion choice.
    public var move: Move

    /// `true` when `move` is legal in the model's current game state.
    public var isLegal: Bool

    /// Source square in algebraic coordinate form, such as `e2`.
    public var sourceSquare: String

    /// Target square in algebraic coordinate form, such as `e4`.
    public var targetSquare: String

    /// Coordinate move string, such as `e2e4` or `e7e8q`.
    public var coordinateMove: String

    /// Promotion piece selected by the user, if the attempt is a promotion.
    public var promotion: PieceKind?

    /// Creates a move attempt value.
    public init(
        move: Move,
        isLegal: Bool,
        sourceSquare: String,
        targetSquare: String,
        coordinateMove: String,
        promotion: PieceKind? = nil
    ) {
        self.move = move
        self.isLegal = isLegal
        self.sourceSquare = sourceSquare
        self.targetSquare = targetSquare
        self.coordinateMove = coordinateMove
        self.promotion = promotion
    }
}

/// Callback invoked when a user attempts a move on `ChessBoardView`.
///
/// The callback is invoked according to the model's
/// `ChessBoardInteractionMode`.
public typealias ChessBoardMoveHandler = (ChessBoardMoveAttempt) -> Void

/// User-interaction policy for `ChessBoardView`.
///
/// Interaction modes control what user gestures ChessUI reports. They do not
/// change chess rules or apply moves; the app remains responsible for acting on
/// any reported `ChessBoardMoveAttempt`.
public enum ChessBoardInteractionMode: String, CaseIterable, Identifiable, Sendable {
    /// Disables tap and drag move gestures while still rendering board state.
    case readOnly

    /// Reports only legal move attempts for the side to move.
    case legalMovesOnly

    /// Reports legal and illegal move attempts for the side to move.
    case reportsIllegalAttempts

    /// Reports legal and illegal move attempts for either side's pieces.
    ///
    /// Use this for setup or editor-style surfaces where the app decides how
    /// to interpret a piece drag. ChessUI still reports whether the coordinate
    /// move is legal in the current `Game`.
    case freeSetup

    /// Stable identifier for picker and list usage.
    public var id: String { rawValue }

    func canInteract(with piece: Piece, turn: PieceColor) -> Bool {
        switch self {
        case .readOnly:
            false
        case .legalMovesOnly, .reportsIllegalAttempts:
            piece.color == turn
        case .freeSetup:
            true
        }
    }

    func shouldReportMove(isLegal: Bool) -> Bool {
        switch self {
        case .readOnly:
            false
        case .legalMovesOnly:
            isLegal
        case .reportsIllegalAttempts, .freeSetup:
            true
        }
    }
}

/// A zero-based board square used by ChessUI state and highlighting APIs.
///
/// `BoardSquare` mirrors `Square`'s file/rank indexing but uses row/column
/// names that are convenient for board rendering.
public struct BoardSquare: Identifiable, Hashable, Sendable {
    /// Zero-based rank index, where `0` is rank 1.
    public var row: Int

    /// Zero-based file index, where `0` is file a.
    public var column: Int

    /// Creates a board square from zero-based row and column indexes.
    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    /// Stable identifier combining row and column.
    public var id: String {
        "\(row),\(column)"
    }

    /// Adds row and column to the supplied hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }

    /// Returns `true` when two board squares have the same row and column.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.row == rhs.row && lhs.column == rhs.column
    }

    /// Returns `true` when two board squares have different row or column values.
    public static func != (lhs: Self, rhs: Self) -> Bool {
        lhs.row != rhs.row || lhs.column != rhs.column
    }
}

/// Observable state model for `ChessBoardView`.
///
/// Use this model to load positions, control board perspective and highlights,
/// apply move-feedback animations, and inspect the underlying `Game`. Invalid
/// FEN input is reported through `fenError` instead of crashing.
///
/// ```swift
/// @State private var model = ChessBoardModel(fen: initialFEN)
///
/// ChessBoardView(model: model)
///     .onMove { attempt in
///         guard attempt.isLegal else { return }
///         model.game.apply(move: attempt.move)
///         let fen = FENSerializer().fen(from: model.game.position)
///         model.setFEN(fen, animatedMove: attempt.move)
///     }
/// ```
@Observable
public class ChessBoardModel {
    private static func emptyPosition() -> Position {
        try! FENSerializer().position(from: emptyFEN)
    }

    /// Current board position as FEN.
    ///
    /// Assigning invalid FEN leaves the current position unchanged and stores
    /// the parser error in `fenError`. Prefer `setFEN(_:animatedMove:)` when a
    /// position change corresponds to a known move and should animate.
    public var fen: String {
        get { FENSerializer().fen(from: game.position) }
        set {
            setFEN(newValue)
        }
    }
    
    /// Current rendered board size in points.
    public var size: CGFloat = 0

    /// Board theme used for squares, labels, and markers.
    public var boardTheme: ChessBoardTheme = .artDecoMonochrome {
        didSet {
            lastMoveHighlightColor = boardTheme.lastMoveHighlight
        }
    }

    /// Piece artwork used by the board and promotion picker.
    public var pieceSet: ChessPieceSet = .sashiteMerida

    /// Controls whether rank and file coordinate labels render on the board.
    public var showsCoordinateLabels: Bool = true

    /// Side displayed at the bottom of the board.
    public var perspective: PieceColor

    /// Side to move in the current game state.
    public var turn: PieceColor { game.position.state.turn }

    /// User-interaction policy for tap and drag move gestures.
    public var interactionMode: ChessBoardInteractionMode = .reportsIllegalAttempts

    /// Controls whether the board shows a non-interactive waiting overlay.
    public var isWaiting = false

    /// Currently selected square, if any.
    public var selectedSquare: BoardSquare?

    /// Squares currently highlighted as hints.
    public var hintedSquares: Set<BoardSquare> = []

    /// Arrows currently rendered over the board.
    public var arrows: [ChessBoardArrow] = []

    /// Controls whether selecting or dragging a piece highlights legal
    /// destinations.
    public var showsLegalMoveHighlights: Bool = true

    /// Legal destination squares for the current selection or drag.
    public var legalMoveSquares: Set<BoardSquare> = []

    /// Duration, in seconds, used when ChessUI animates a piece from the
    /// source square to the destination square after `setFEN(_:animatedMove:)`.
    ///
    /// Set this to `0` to make move updates effectively immediate. The default
    /// is tuned to feel similar to common online chess boards.
    public var moveAnimationDuration: Double = 0.45

    /// Controls whether ChessUI keeps the source and destination squares of
    /// the most recent move highlighted after `setFEN(_:animatedMove:)`.
    public var showsLastMoveHighlight: Bool = true

    /// Color used to highlight the source and destination squares of the most
    /// recent move.
    public var lastMoveHighlightColor: Color = ChessBoardTheme.artDecoMonochrome.lastMoveHighlight

    /// Source and destination squares for the most recent move passed through
    /// `setFEN(_:animatedMove:)`. Direct `fen` assignment clears this value
    /// because a raw FEN string does not reliably identify the move that
    /// produced it.
    public private(set) var lastMoveSquares: (from: BoardSquare, to: BoardSquare)?
    
    /// Controls presentation of the built-in promotion picker.
    public var isPromotionPickerPresented = false

    /// Underlying chess game backing the board.
    ///
    /// Apps may inspect or mutate this game directly, but the board only
    /// redraws from the model's current position. After applying a move, call
    /// `setFEN(_:animatedMove:)` when you want ChessUI's move feedback.
    public var game: Game

    /// The most recent FEN parsing error produced by `fen` assignment or
    /// `setFEN(_:animatedMove:)`. A successful position update clears this.
    public private(set) var fenError: Error?
    
    /// Move currently being animated, if any.
    public var animatedMove: Move? = nil

    /// Pawn awaiting promotion selection, if any.
    public var promotionPiece: Piece?

    /// Source square for the pending promotion move.
    public var promotionSourceSquare: String?

    /// Destination square for the pending promotion move.
    public var promotionTargetSquare: String?

    /// Base non-promoting move for the pending promotion choice.
    public var promotionBaseMove: Move?

    /// `true` when Black is displayed at the bottom of the board.
    public var shouldFlipBoard: Bool { perspective == .black }

    /// Piece currently rendered by the move-feedback overlay.
    public var movingPiece: (piece: Piece, from: BoardSquare, to: BoardSquare)?
    
    /// Creates a chess board model.
    ///
    /// Invalid initial FEN falls back to `emptyFEN` and stores the parse error
    /// in `fenError`, which lets app UI present diagnostics without crashing.
    ///
    /// - Parameters:
    ///   - fen: Initial board position.
    ///   - perspective: Side displayed at the bottom of the board.
    ///   - boardTheme: Board styling used for squares, labels, and markers.
    ///   - pieceSet: Built-in piece artwork used by the board.
    ///   - showsCoordinateLabels: Shows rank and file coordinate labels on
    ///     the board.
    ///   - arrows: App-supplied display arrows rendered over the board.
    ///   - interactionMode: User-interaction policy for tap and drag move
    ///     gestures.
    ///   - showsLegalMoveHighlights: Shows legal destination markers while a piece
    ///     is selected or dragged.
    ///   - moveAnimationDuration: Duration, in seconds, for move animations
    ///     triggered by `setFEN(_:animatedMove:)`.
    ///   - showsLastMoveHighlight: Keeps the source and destination squares of
    ///     the last move highlighted after `setFEN(_:animatedMove:)`.
    public init(fen: String = emptyFEN,
                perspective: PieceColor = .white,
                boardTheme: ChessBoardTheme = .artDecoMonochrome,
                pieceSet: ChessPieceSet = .sashiteMerida,
                showsCoordinateLabels: Bool = true,
                arrows: [ChessBoardArrow] = [],
                interactionMode: ChessBoardInteractionMode = .reportsIllegalAttempts,
                showsLegalMoveHighlights: Bool = true,
                moveAnimationDuration: Double = 0.45,
                showsLastMoveHighlight: Bool = true)
    {
        do {
            self.game = Game(position: try FENSerializer().position(from: fen))
            self.fenError = nil
        } catch {
            self.game = Game(position: Self.emptyPosition())
            self.fenError = error
        }
        self.perspective = perspective
        self.boardTheme = boardTheme
        self.pieceSet = pieceSet
        self.showsCoordinateLabels = showsCoordinateLabels
        self.arrows = arrows
        self.interactionMode = interactionMode
        self.showsLegalMoveHighlights = showsLegalMoveHighlights
        self.moveAnimationDuration = max(0, moveAnimationDuration)
        self.showsLastMoveHighlight = showsLastMoveHighlight
        self.lastMoveHighlightColor = boardTheme.lastMoveHighlight
    }

    /// Callback invoked when the user attempts a move on the board.
    public var onMove: ChessBoardMoveHandler = { _ in }

    /// Board square currently targeted by an active drag gesture.
    public var dropTarget: (row: Int, column: Int)?

    /// Replaces the current board position and, when `animatedMove` is supplied,
    /// animates the moved piece from source to destination and highlights both
    /// squares.
    ///
    /// Use this method for interactive play and engine replies. Directly
    /// assigning `fen` is still supported for arbitrary position loading, but
    /// direct assignment clears move-specific animation and highlight state
    /// because a FEN string alone does not identify the source square.
    ///
    /// - Returns: `true` when the FEN was parsed and applied, or `false` when
    ///   parsing failed and the previous board was left unchanged.
    @discardableResult
    public func setFEN(_ fen: String, animatedMove: Move? = nil) -> Bool {
        let newGame: Game
        do {
            newGame = Game(position: try FENSerializer().position(from: fen))
            fenError = nil
        } catch {
            fenError = error
            return false
        }

        self.animatedMove = animatedMove
        movingPiece = nil
        lastMoveSquares = nil

        if let animatedMove = self.animatedMove {
            let pieces = game.position.board.enumeratedPieces()
            let squareAndPiece = pieces.first { $0.0 == animatedMove.from }
            
            let from = BoardSquare(row: animatedMove.from.rank, column: animatedMove.from.file)
            let to = BoardSquare(row: animatedMove.to.rank, column: animatedMove.to.file)

            lastMoveSquares = (from: from, to: to)

            if let piece = squareAndPiece?.1 ?? newGame.position.board[animatedMove.to] {
                movingPiece = (piece: piece, from: from, to: to)
            }
        }
        
        game = newGame
        return true
    }

    /// Clears the persisted last-move source and destination square highlight.
    public func clearLastMoveHighlight() {
        lastMoveSquares = nil
    }

    /// Clears the current board selection and legal-move markers.
    public func deselect() {
        selectedSquare = nil
        legalMoveSquares.removeAll()
    }

    /// Refreshes legal destination markers for a selected or dragged square.
    ///
    /// Markers are derived from the model's current `game.legalMoves`; callers
    /// do not need to compute legal destinations themselves.
    public func updateLegalMoveHighlights(for square: BoardSquare) {
        guard showsLegalMoveHighlights else {
            legalMoveSquares.removeAll()
            return
        }
        
        legalMoveSquares.removeAll()
        
        let index = square.row + square.column * 8
        guard game.position.board[index] != nil else { return }
        
        for move in game.legalMoves {
            if move.from.rank == square.row && move.from.file == square.column {
                let targetSquare = BoardSquare(row: move.to.rank, column: move.to.file)
                legalMoveSquares.insert(targetSquare)
            }
        }
    }

    /// Clears all legal destination markers.
    public func clearLegalMoveHighlights() {
        legalMoveSquares.removeAll()
    }

    /// Adds a hint highlight for a board square.
    public func hint(_ square: BoardSquare) {
        hintedSquares.insert(square)
    }

    /// Adds a hint highlight for an algebraic coordinate such as `e4`.
    ///
    /// Invalid coordinates are ignored.
    public func hint(_ square: String) {
        if square.count != 2 {
            return
        }
        
        let fileChar = square.first!
        let rankChar = square.last!
        
        let file = "abcdefgh".firstIndex(of: fileChar)?.utf16Offset(in: "abcdefgh")
        let rank = Int(String(rankChar))
        
        guard let file = file, let rank = rank else {
            return
        }
        
        let row = rank - 1
        let column = file
        
        hint(BoardSquare(row: row, column: column))
    }

    /// Adds a hint highlight for a zero-based row and column.
    public func hint(row: Int, column: Int) {
        hint(BoardSquare(row: row, column: column))
    }

    /// Adds hint highlights for multiple board squares.
    public func hint(_ squares: [BoardSquare]) {
        for square in squares {
            hint(square)
        }
    }

    /// Adds hint highlights for multiple algebraic coordinates.
    public func hint(_ squares: [String]) {
        for square in squares {
            hint(square)
        }
    }

    /// Clears all hint highlights.
    public func clearHint() {
        hintedSquares.removeAll()
    }

    /// Clears all app-supplied board arrows.
    public func clearArrows() {
        arrows.removeAll()
    }

    /// Adds a coordinate hint, then clears all hints after `seconds`.
    @MainActor
    public func hint(_ square: String, for seconds: Double) {
        withAnimation {
            hint(square)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }

    /// Adds coordinate hints, then clears all hints after `seconds`.
    @MainActor
    public func hint(_ squares: [String], for seconds: Double) {
        withAnimation {
            hint(squares)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }

    /// Adds board-square hints, then clears all hints after `seconds`.
    @MainActor
    public func hint(_ squares: [BoardSquare], for seconds: Double) {
        withAnimation {
            hint(squares)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }

    /// Adds a board-square hint, then clears all hints after `seconds`.
    @MainActor
    public func hint(_ square: BoardSquare, for seconds: Double) {
        withAnimation {
            hint(square)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }

    /// Presents the built-in promotion picker for a pending promotion move.
    ///
    /// The picker reports a promoted `ChessBoardMoveAttempt`; the app still
    /// decides whether and how to apply it.
    public func presentPromotionPicker(piece: Piece, sourceSquare: String, targetSquare: String, baseMove: Move) {
        promotionPiece = piece
        promotionSourceSquare = sourceSquare
        promotionTargetSquare = targetSquare
        promotionBaseMove = baseMove
        
        withAnimation(.bouncy) {
            isPromotionPickerPresented = true
        }
    }

    /// Dismisses the built-in promotion picker and clears pending promotion state.
    public func dismissPromotionPicker() {
        promotionPiece = nil
        promotionSourceSquare = nil
        promotionTargetSquare = nil
        promotionBaseMove = nil
        
        withAnimation(.bouncy) {
            isPromotionPickerPresented = false
        }
    }

    /// Toggles presentation of the built-in promotion picker.
    public func togglePromotionPicker() {
        withAnimation(.bouncy) {
            isPromotionPickerPresented.toggle()
        }
    }

    /// Returns `true` when the move needs an explicit promotion-piece choice.
    public func requiresPromotionChoice(piece: Piece, move: Move) -> Bool {
        guard piece.kind == .pawn else { return false }
        return move.to.rank == (piece.color == .white ? 7 : 0)
    }

    /// Shows the non-interactive waiting overlay.
    public func showWaitingOverlay() {
        withAnimation(.bouncy) {
            isWaiting = true
        }
    }

    /// Hides the non-interactive waiting overlay.
    public func hideWaitingOverlay() {
        withAnimation(.bouncy) {
            isWaiting = false
        }
    }

    func reportMove(
        _ move: Move,
        isLegal: Bool,
        sourceSquare: String,
        targetSquare: String,
        coordinateMove: String,
        promotion: PieceKind? = nil
    ) {
        guard interactionMode.shouldReportMove(isLegal: isLegal) else {
            return
        }

        onMove(
            ChessBoardMoveAttempt(
                move: move,
                isLegal: isLegal,
                sourceSquare: sourceSquare,
                targetSquare: targetSquare,
                coordinateMove: coordinateMove,
                promotion: promotion
            )
        )
    }
}

private struct MovingPieceView: View {
    var animation: Namespace.ID
    
    @Environment(ChessBoardModel.self) var boardModel
    
    @State private var position: CGPoint?
    
    var body: some View {
        Group {
            if let movingPiece = boardModel.movingPiece {
                ChessPieceView(animation: animation,
                               piece: movingPiece.piece,
                               square: BoardSquare(row: movingPiece.from.row, column: movingPiece.from.column),
                               isMovingPiece: true)
                .allowsHitTesting(false)
                .position(position ?? squareCenter(for: movingPiece.from))
                .task(id: movingPieceIdentity(movingPiece)) {
                    await animate(movingPiece)
                }
            }
        }
    }

    private func movingPieceIdentity(_ movingPiece: (piece: Piece, from: BoardSquare, to: BoardSquare)) -> String {
        "\(movingPiece.piece.color)-\(movingPiece.piece.kind)-\(movingPiece.from.id)-\(movingPiece.to.id)"
    }

    private func squareCenter(for square: BoardSquare) -> CGPoint {
        CGPoint(
            x: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? 7 - square.column : square.column),
            y: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? square.row : 7 - square.row)
        )
    }

    @MainActor
    private func animate(_ movingPiece: (piece: Piece, from: BoardSquare, to: BoardSquare)) async {
        let source = squareCenter(for: movingPiece.from)
        let destination = squareCenter(for: movingPiece.to)
        let duration = max(0, boardModel.moveAnimationDuration)

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            position = source
        }

        guard duration > 0 else {
            position = destination
            clearMovingPieceIfCurrent(movingPiece)
            return
        }

        // Give SwiftUI one display pass at the source square before starting
        // the animated travel. Without this, source and destination updates can
        // be coalesced into a single snap on fast board updates.
        try? await Task.sleep(for: .milliseconds(20))
        guard isCurrent(movingPiece) else { return }

        withAnimation(.easeInOut(duration: duration)) {
            position = destination
        } completion: {
            clearMovingPieceIfCurrent(movingPiece)
        }
    }

    private func isCurrent(_ movingPiece: (piece: Piece, from: BoardSquare, to: BoardSquare)) -> Bool {
        boardModel.movingPiece?.piece == movingPiece.piece &&
        boardModel.movingPiece?.from == movingPiece.from &&
        boardModel.movingPiece?.to == movingPiece.to
    }

    private func clearMovingPieceIfCurrent(_ movingPiece: (piece: Piece, from: BoardSquare, to: BoardSquare)) {
        guard isCurrent(movingPiece) else { return }
        boardModel.movingPiece = nil
        position = nil
    }
}

private struct ChessBoardSquareBackground: View {
    var theme: ChessBoardTheme
    var isLightSquare: Bool
    var row: Int
    var column: Int

    private var baseColor: Color {
        isLightSquare ? theme.lightSquare : theme.darkSquare
    }

    var body: some View {
        Rectangle()
            .fill(baseColor)
            .overlay {
                textureView
            }
            .clipped()
    }

    @ViewBuilder
    private var textureView: some View {
        switch theme.texture {
        case .none:
            EmptyView()
        case .wood:
            ChessBoardWoodTexture(isLightSquare: isLightSquare, row: row, column: column)
        case .marble:
            ChessBoardMarbleTexture(isLightSquare: isLightSquare, row: row, column: column)
        case .blueprint:
            ChessBoardBlueprintTexture(isLightSquare: isLightSquare)
        case .artDeco:
            ChessBoardArtDecoTexture(isLightSquare: isLightSquare, row: row, column: column)
        case .circuit:
            ChessBoardCircuitTexture(isLightSquare: isLightSquare, row: row, column: column)
        case .sportsCourt:
            ChessBoardSportsCourtTexture(isLightSquare: isLightSquare, row: row, column: column)
        }
    }
}

private struct ChessBoardWoodTexture: View {
    var isLightSquare: Bool
    var row: Int
    var column: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let darkLine = Color.black.opacity(isLightSquare ? 0.07 : 0.12)
            let lightLine = Color.white.opacity(isLightSquare ? 0.10 : 0.06)

            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(isLightSquare ? 0.12 : 0.06),
                        Color.black.opacity(isLightSquare ? 0.04 : 0.10),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<4, id: \.self) { index in
                    Path { path in
                        let y = size.height * (0.18 + CGFloat(index) * 0.22)
                        let offset = CGFloat((row + column + index) % 3) * size.height * 0.025
                        path.move(to: CGPoint(x: 0, y: y + offset))
                        path.addCurve(
                            to: CGPoint(x: size.width, y: y - offset),
                            control1: CGPoint(x: size.width * 0.32, y: y + size.height * 0.05),
                            control2: CGPoint(x: size.width * 0.66, y: y - size.height * 0.05)
                        )
                    }
                    .stroke(index.isMultiple(of: 2) ? darkLine : lightLine, lineWidth: max(0.8, size.width * 0.018))
                }
            }
        }
    }
}

private struct ChessBoardMarbleTexture: View {
    var isLightSquare: Bool
    var row: Int
    var column: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let vein = isLightSquare ? Color.black.opacity(0.12) : Color.white.opacity(0.12)
            let secondary = isLightSquare ? Color.white.opacity(0.20) : Color.black.opacity(0.10)

            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(isLightSquare ? 0.22 : 0.08),
                        Color.black.opacity(isLightSquare ? 0.04 : 0.12),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<3, id: \.self) { index in
                    Path { path in
                        let bias = CGFloat((row * 3 + column + index) % 5) * size.width * 0.04
                        let startY = size.height * (0.16 + CGFloat(index) * 0.26)
                        path.move(to: CGPoint(x: -size.width * 0.10, y: startY + bias))
                        path.addCurve(
                            to: CGPoint(x: size.width * 1.10, y: startY + size.height * 0.18 - bias),
                            control1: CGPoint(x: size.width * 0.20, y: startY - size.height * 0.16),
                            control2: CGPoint(x: size.width * 0.70, y: startY + size.height * 0.28)
                        )
                    }
                    .stroke(index == 1 ? secondary : vein, lineWidth: max(0.7, size.width * 0.018))
                }
            }
        }
    }
}

private struct ChessBoardBlueprintTexture: View {
    var isLightSquare: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let major = Color.white.opacity(isLightSquare ? 0.18 : 0.24)
            let minor = Color.white.opacity(isLightSquare ? 0.10 : 0.14)

            ZStack {
                ForEach(1..<4, id: \.self) { index in
                    Path { path in
                        let position = CGFloat(index) * size.width / 4
                        path.move(to: CGPoint(x: position, y: 0))
                        path.addLine(to: CGPoint(x: position, y: size.height))
                        path.move(to: CGPoint(x: 0, y: position))
                        path.addLine(to: CGPoint(x: size.width, y: position))
                    }
                    .stroke(index == 2 ? major : minor, lineWidth: max(0.5, size.width * 0.012))
                }
            }
        }
    }
}

private struct ChessBoardArtDecoTexture: View {
    var isLightSquare: Bool
    var row: Int
    var column: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let line = isLightSquare ? Color.black.opacity(0.08) : Color.white.opacity(0.12)
            let accent = isLightSquare ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
            let flipped = (row + column).isMultiple(of: 2)

            ZStack {
                Path { path in
                    if flipped {
                        path.move(to: CGPoint(x: size.width * 0.18, y: 0))
                        path.addLine(to: CGPoint(x: size.width, y: size.height * 0.82))
                        path.move(to: CGPoint(x: 0, y: size.height * 0.32))
                        path.addLine(to: CGPoint(x: size.width * 0.68, y: size.height))
                    } else {
                        path.move(to: CGPoint(x: size.width * 0.82, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: size.height * 0.82))
                        path.move(to: CGPoint(x: size.width, y: size.height * 0.32))
                        path.addLine(to: CGPoint(x: size.width * 0.32, y: size.height))
                    }
                }
                .stroke(line, lineWidth: max(0.8, size.width * 0.025))

                Rectangle()
                    .stroke(accent, lineWidth: max(0.5, size.width * 0.012))
                    .padding(size.width * 0.18)
            }
        }
    }
}

private struct ChessBoardCircuitTexture: View {
    var isLightSquare: Bool
    var row: Int
    var column: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let trace = isLightSquare ? Color.white.opacity(0.16) : Color(red: 0.55, green: 0.95, blue: 0.72).opacity(0.22)
            let node = trace.opacity(0.85)
            let horizontalFirst = (row + column).isMultiple(of: 2)

            ZStack {
                Path { path in
                    if horizontalFirst {
                        path.move(to: CGPoint(x: 0, y: size.height * 0.36))
                        path.addLine(to: CGPoint(x: size.width * 0.58, y: size.height * 0.36))
                        path.addLine(to: CGPoint(x: size.width * 0.58, y: size.height))
                    } else {
                        path.move(to: CGPoint(x: size.width * 0.36, y: 0))
                        path.addLine(to: CGPoint(x: size.width * 0.36, y: size.height * 0.62))
                        path.addLine(to: CGPoint(x: size.width, y: size.height * 0.62))
                    }
                }
                .stroke(trace, lineWidth: max(0.8, size.width * 0.018))

                Circle()
                    .stroke(node, lineWidth: max(0.7, size.width * 0.014))
                    .frame(width: size.width * 0.16, height: size.width * 0.16)
                    .position(
                        x: horizontalFirst ? size.width * 0.58 : size.width * 0.36,
                        y: horizontalFirst ? size.height * 0.36 : size.height * 0.62
                    )
            }
        }
    }
}

private struct ChessBoardSportsCourtTexture: View {
    var isLightSquare: Bool
    var row: Int
    var column: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let grain = isLightSquare ? Color.white.opacity(0.12) : Color.black.opacity(0.10)
            let courtLine = Color.white.opacity(isLightSquare ? 0.24 : 0.18)

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Path { path in
                        let y = size.height * (0.24 + CGFloat(index) * 0.24)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y + CGFloat((row + column + index) % 2) * 1.4))
                    }
                    .stroke(grain, lineWidth: max(0.7, size.width * 0.014))
                }

                if row == 3 || row == 4 || column == 3 || column == 4 {
                    Rectangle()
                        .stroke(courtLine, lineWidth: max(0.8, size.width * 0.018))
                        .padding(size.width * 0.22)
                }
            }
        }
    }
}

/// SwiftUI chessboard view backed by `ChessBoardModel`.
///
/// The view renders the board, pieces, markers, move gestures, promotion UI,
/// and move callbacks. It does not apply moves by itself; callers update the
/// model after deciding whether a reported move should change the game state.
///
/// Keep `ChessBoardModel` owned by your app, usually with `@State`, and pass it
/// into the board view. Use `.onMove(_:)` to bridge user gestures back into
/// your app's game logic. Board squares also expose accessibility actions that
/// follow the same select-source, activate-destination flow as taps.
public struct ChessBoardView: View {
    /// State model rendered and mutated by the board.
    public var model: ChessBoardModel
    
    @Namespace private var animation
    
    /// Creates a chessboard view for the provided model.
    public init(model: ChessBoardModel) {
        self.model = model
    }

    private var boardModel: ChessBoardModel { model }

    /// SwiftUI content for the chessboard and its overlays.
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                lastMoveHighlightsView
                    .allowsHitTesting(false)
                if model.showsCoordinateLabels {
                    labelsView
                        .allowsHitTesting(false)
                }
                squaresView
                arrowsView
                    .allowsHitTesting(false)
                piecesView
                legalMoveHighlightsView
                    .allowsHitTesting(false)
                
                MovingPieceView(animation: animation)
                
                if model.isPromotionPickerPresented {
                    promotionPickerView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                if model.isWaiting {
                    waitingOverlayView
                }
            }
            .environment(model)
            .frame(width: boardSize(from: geometry.size),
                   height: boardSize(from: geometry.size))
            .onAppear {
                updateBoardSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                updateBoardSize(newSize)
            }
            .onChange(of: model.boardTheme) { _, _ in
                updateBoardSize(geometry.size)
            }
            .onChange(of: model.pieceSet) { _, _ in
                updateBoardSize(geometry.size)
            }
            .task {
                updateBoardSize(geometry.size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func boardSize(from geometrySize: CGSize) -> CGFloat {
        return min(geometrySize.width, geometrySize.height)
    }

    private func updateBoardSize(_ geometrySize: CGSize) {
        let newSize = boardSize(from: geometrySize)
        guard newSize > 0 else {
            return
        }
        model.size = newSize
    }
    
    var waitingOverlayView: some View {
        ZStack {
            Color.clear.contentShape(Rectangle())
                .ignoresSafeArea()
        }
    }
    
    var promotionPickerView: some View {
        ZStack {
            Color.white.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    ForEach(["q", "r", "b", "n"], id: \.self) { (piece: String) in
                        Button {
                            guard let sourceSquare = boardModel.promotionSourceSquare,
                                  let targetSquare = boardModel.promotionTargetSquare,
                                  let baseMove = boardModel.promotionBaseMove,
                                  let promotion = PieceKind(rawValue: piece)
                            else {
                                boardModel.dismissPromotionPicker()
                                return
                            }
                            
                            let promotedMove = Move(from: baseMove.from, to: baseMove.to, promotion: promotion)
                            let promotedCoordinateMove = promotedMove.description
                            let isLegal = boardModel.game.legalMoves.contains(promotedMove)
                            
                            boardModel.reportMove(
                                promotedMove,
                                isLegal: isLegal,
                                sourceSquare: sourceSquare,
                                targetSquare: targetSquare,
                                coordinateMove: promotedCoordinateMove,
                                promotion: promotion
                            )
                            
                            boardModel.dismissPromotionPicker()
                        } label: {
                            let promotionColor: PieceColor = boardModel.perspective == .white ? .white : .black
                            let promotionPiece = Piece(kind: PieceKind(rawValue: piece)!, color: promotionColor)
                            let imageName = boardModel.pieceSet.assetName(for: promotionPiece)
                            
                            ZStack {
                                PieceImageView(imageName: imageName,
                                               pieceSet: boardModel.pieceSet,
                                               fallback: piece.uppercased(),
                                               fallbackColor: Color.black)
                                    .frame(width: boardModel.size / 8,
                                           height: boardModel.size / 8)
                            }
                            .padding(5)
                        }
                        .background(.white)
                        .cornerRadius(12)
                        .accessibilityIdentifier("ChessUI.promotion.\(promotionName(for: piece))")
                        .accessibilityLabel("Promote to \(promotionName(for: piece))")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Choose promotion piece")
        }
    }

    private func promotionName(for piece: String) -> String {
        switch piece {
        case "q": "queen"
        case "r": "rook"
        case "b": "bishop"
        case "n": "knight"
        default: piece
        }
    }
    
    var backgroundView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8), spacing: 0) {
            ForEach(0..<64) { index in
                let row = index / 8
                let column = index % 8
                let isLightSquare = (row + column) % 2 == 0
                
                ChessBoardSquareBackground(
                    theme: boardModel.boardTheme,
                    isLightSquare: isLightSquare,
                    row: row,
                    column: column
                )
                    .frame(width: boardModel.size / 8, height: boardModel.size / 8)
            }
        }
    }

    var lastMoveHighlightsView: some View {
        ZStack {
            if boardModel.showsLastMoveHighlight,
               let lastMoveSquares = boardModel.lastMoveSquares
            {
                ForEach([lastMoveSquares.from, lastMoveSquares.to], id: \.id) { square in
                    Rectangle()
                        .fill(boardModel.lastMoveHighlightColor)
                        .frame(width: boardModel.size / 8, height: boardModel.size / 8)
                        .position(position(for: square))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Last move \(coordinate(for: square))")
                        .accessibilityIdentifier("ChessUI.lastMove.\(coordinate(for: square))")
                }
            }
        }
    }
    
    var labelsView: some View {
        ZStack {
            ForEach(0..<8) { row in
                rowLabelView(row: row)
            }
            
            ForEach(0..<8) { column in
                columnLabelView(column: column)
            }
        }
    }
    
    func rowLabelView(row: Int) -> some View {
        let displayRow = boardModel.shouldFlipBoard ? (7 - row) : row
        let labelSize = boardModel.size / 32
        let squareSize = boardModel.size / 8
        let rankLabelDownshift = max(1, labelSize * 0.08)
        
        return Text("\(displayRow + 1)")
            .font(.system(size: labelSize))
            .foregroundColor(boardModel.boardTheme.label)
            .frame(width: labelSize, height: squareSize, alignment: .center)
            .position(
                x: labelSize / 2 + 2,
                y: boardModel.size
                    - (CGFloat(row) * squareSize + squareSize - 10)
                    + rankLabelDownshift
            )
    }
    
    func columnLabelView(column: Int) -> some View {
        let displayColumn = boardModel.shouldFlipBoard ? 7 - column : column
        let labelSize = boardModel.size / 32
        let squareSize = boardModel.size / 8
        let fileLabelLeftShift = max(0.5, labelSize * 0.04)
        
        return Text(["a", "b", "c", "d", "e", "f", "g", "h"][displayColumn])
            .font(.system(size: labelSize))
            .foregroundColor(boardModel.boardTheme.label)
            .frame(width: squareSize, height: labelSize, alignment: .center)
            .position(
                x: (CGFloat(column) * squareSize + squareSize)
                    - 8
                    - fileLabelLeftShift,
                y: (boardModel.size - labelSize / 2) - 4
            )
    }
    
    var squaresView: some View {
        ZStack {
            ForEach(0..<64, id: \.self) { index in
                let row = index % 8
                let column = index / 8
                let piece = boardModel.game.position.board[index]
                
                ChessSquareView(piece: piece,
                                row: row,
                                column: column)
                .position(x: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? 7 - column : column),
                          y: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? row : 7 - row))
            }
        }
    }
    
    var piecesView: some View {
        ZStack {
            ForEach(0..<64, id: \.self) { index in
                let row = index % 8
                let column = index / 8
                let piece = boardModel.game.position.board[index]
                
                let isMoving = boardModel.movingPiece?.from == BoardSquare(row: row, column: column) ||
                               boardModel.movingPiece?.to == BoardSquare(row: row, column: column)
                
                ChessPieceView(animation: animation,
                               piece: piece,
                               square: BoardSquare(row: row, column: column))
                .opacity(isMoving ? 0.0 : 1.0)
                .animation(nil, value: isMoving)
                .position(x: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? 7 - column : column),
                          y: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? row : 7 - row))
            }
        }
    }
    
    var legalMoveHighlightsView: some View {
        ZStack {
            ForEach(Array(boardModel.legalMoveSquares), id: \.id) { square in
                Circle()
                    .fill(boardModel.boardTheme.legalMove)
                    .frame(width: boardModel.size / 24, height: boardModel.size / 24)
                    .position(position(for: square))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Legal move \(coordinate(for: square))")
                    .accessibilityIdentifier("ChessUI.legalMove.\(coordinate(for: square))")
            }
        }
    }

    var arrowsView: some View {
        ZStack {
            ForEach(Array(boardModel.arrows.enumerated()), id: \.offset) { _, arrow in
                if isOnBoard(arrow.from),
                   isOnBoard(arrow.to),
                   arrow.from != arrow.to
                {
                    ChessBoardArrowView(
                        arrow: arrow,
                        start: position(for: arrow.from),
                        end: position(for: arrow.to),
                        squareSize: boardModel.size / 8
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(for: arrow))
                    .accessibilityIdentifier("ChessUI.arrow.\(coordinate(for: arrow.from)).\(coordinate(for: arrow.to))")
                }
            }
        }
    }

    private func position(for square: BoardSquare) -> CGPoint {
        CGPoint(
            x: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? 7 - square.column : square.column),
            y: boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? square.row : 7 - square.row)
        )
    }

    private func coordinate(for square: BoardSquare) -> String {
        let file = Character(UnicodeScalar(square.column + 97)!)
        return "\(file)\(square.row + 1)"
    }

    private func isOnBoard(_ square: BoardSquare) -> Bool {
        (0...7).contains(square.row) && (0...7).contains(square.column)
    }

    private func accessibilityLabel(for arrow: ChessBoardArrow) -> String {
        arrow.label ?? "Arrow \(coordinate(for: arrow.from)) to \(coordinate(for: arrow.to))"
    }
    
    /// Registers a callback for attempted board moves.
    public func onMove(_ callback: @escaping ChessBoardMoveHandler) -> ChessBoardView {
        boardModel.onMove = callback
        return self
    }
}

private struct ChessBoardArrowView: View {
    var arrow: ChessBoardArrow
    var start: CGPoint
    var end: CGPoint
    var squareSize: CGFloat

    var body: some View {
        if let geometry {
            ZStack {
                Path { path in
                    path.move(to: geometry.lineStart)
                    path.addLine(to: geometry.lineEnd)
                }
                .stroke(
                    arrow.style.color.opacity(arrow.style.opacity),
                    style: StrokeStyle(
                        lineWidth: geometry.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                Path { path in
                    path.move(to: end)
                    path.addLine(to: geometry.headBaseA)
                    path.addLine(to: geometry.headBaseB)
                    path.closeSubpath()
                }
                .fill(arrow.style.color.opacity(arrow.style.opacity))
            }
        }
    }

    private var geometry: ArrowGeometry? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 1 else { return nil }

        let unitX = dx / length
        let unitY = dy / length
        let lineWidth = max(1, min(arrow.style.lineWidth, squareSize * 0.28))
        let requestedHeadLength = max(squareSize * 0.22, lineWidth * 2.4)
        let headLength = min(requestedHeadLength, length * 0.45)
        let halfHeadWidth = headLength * 0.42
        let baseCenter = CGPoint(
            x: end.x - unitX * headLength,
            y: end.y - unitY * headLength
        )
        let perpendicularX = -unitY
        let perpendicularY = unitX

        return ArrowGeometry(
            lineStart: CGPoint(
                x: start.x + unitX * lineWidth * 0.5,
                y: start.y + unitY * lineWidth * 0.5
            ),
            lineEnd: CGPoint(
                x: end.x - unitX * headLength * 0.46,
                y: end.y - unitY * headLength * 0.46
            ),
            headBaseA: CGPoint(
                x: baseCenter.x + perpendicularX * halfHeadWidth,
                y: baseCenter.y + perpendicularY * halfHeadWidth
            ),
            headBaseB: CGPoint(
                x: baseCenter.x - perpendicularX * halfHeadWidth,
                y: baseCenter.y - perpendicularY * halfHeadWidth
            ),
            lineWidth: lineWidth
        )
    }

    private struct ArrowGeometry {
        var lineStart: CGPoint
        var lineEnd: CGPoint
        var headBaseA: CGPoint
        var headBaseB: CGPoint
        var lineWidth: CGFloat
    }
}

private struct ChessSquareView: View {
    @Environment(ChessBoardModel.self) var boardModel
    
    var piece: Piece?
    var row: Int
    var column: Int
    
    @State var offset: CGSize = .zero
    @State var isDragging: Bool = false
    
    var zIndex: Double { isDragging ? 1: 0 }
    
    var isSelected: Bool {
        if let selectedSquare = boardModel.selectedSquare {
            return selectedSquare.row == row && selectedSquare.column == column
        }
        return false
    }
    
    var isHinted: Bool {
        boardModel.hintedSquares.contains { $0.row == row && $0.column == column }
    }
    
    var x: CGFloat {
        boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? 7 - column : column)
    }
    
    var y: CGFloat {
        boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? row : 7 - row)
    }
    
    var body: some View {
        ZStack {
            Color.clear.contentShape(Rectangle())
        }
        .font(.system(size: boardModel.size / 8 * 0.75))
        .frame(width: boardModel.size / 8, height: boardModel.size / 8)
        .overlay {
            if let dropTarget = boardModel.dropTarget,
               !isDragging &&
                dropTarget.row == row && dropTarget.column == column
            {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(boardModel.boardTheme.selected, lineWidth: 3.5)
            } else if isSelected {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(boardModel.boardTheme.selected, lineWidth: 3.5)
            } else if isHinted {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(boardModel.boardTheme.hinted, lineWidth: 3.5)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Hint \(coordinate)")
                    .accessibilityIdentifier("ChessUI.hint.\(coordinate)")
            }
        }
    }

    private var coordinate: String {
        let file = Character(UnicodeScalar(column + 97)!)
        return "\(file)\(row + 1)"
    }
}

private struct ChessPieceView: View {
    @Environment(ChessBoardModel.self) var boardModel
    
    var animation: Namespace.ID
    
    var piece: Piece?
    var square: BoardSquare
    var isMovingPiece = false
    
    @State var offset: CGSize = .zero
    @State var isDragging = false
    
    var zIndex: Double { isDragging ? 1: 0 }
    
    var isSelected: Bool {
        if let selectedSquare = boardModel.selectedSquare {
            return selectedSquare.row == square.row && selectedSquare.column == square.column
        }
        return false
    }
    
    var isHinted: Bool {
        boardModel.hintedSquares.contains { $0.row == square.row && $0.column == square.column }
    }
    
    var x: CGFloat {
        boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? 7 - square.column : square.column)
    }
    
    var y: CGFloat {
        boardModel.size / 16 + boardModel.size / 8 * CGFloat(boardModel.shouldFlipBoard ? square.row : 7 - square.row)
    }
    
    var isMoving: Bool {
        piece == boardModel.movingPiece?.piece && square == boardModel.movingPiece?.from
    }
    
    var body: some View {
        let accessibilityState = boardModel.accessibilityState(for: square)

        ZStack {
            if let piece {
                let imageName = boardModel.pieceSet.assetName(for: piece)
                
                PieceImageView(imageName: imageName,
                               pieceSet: boardModel.pieceSet,
                               fallback: "\(piece)",
                               fallbackColor: piece.color == PieceColor.white ? Color.white : Color.black)
            } else {
                Color.clear.contentShape(Rectangle())
            }
        }
        .zIndex(zIndex)
        .font(.system(size: boardModel.size / 8 * 0.75))
        .frame(width: boardModel.size / 8, height: boardModel.size / 8)
        .contentShape(Rectangle())
        .offset(offset)
        .onTapGesture {
            boardModel.activate(square: square)
        }
        .gesture(dragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityState.label)
        .accessibilityHint(accessibilityState.hint)
        .accessibilityIdentifier("ChessUI.square.\(coordinate)")
        .accessibilityHidden(isMovingPiece)
        .chessBoardAccessibilityTraits(accessibilityState)
        .chessBoardAccessibilityAction(accessibilityState.isActivatable) {
            announceForAccessibility(boardModel.activate(square: square))
        }
    }

    private var coordinate: String {
        square.coordinate
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if boardModel.movingPiece != nil || boardModel.interactionMode == .readOnly {
                    return
                }
                
                if boardModel.selectedSquare != nil {
                    boardModel.deselect()
                }
                
                guard let piece,
                      boardModel.interactionMode.canInteract(with: piece, turn: boardModel.turn)
                else {
                    boardModel.selectedSquare = nil
                    isDragging = false
                    boardModel.clearLegalMoveHighlights()
                    return
                }
                
                boardModel.selectedSquare = nil
                
                if !isDragging {
                    boardModel.updateLegalMoveHighlights(for: BoardSquare(row: square.row, column: square.column))
                }
                
                isDragging = true
                
                let squareSize = boardModel.size / 8
                let columnOffset = Int(round(value.translation.width / squareSize))
                let rowOffset = Int(round(value.translation.height / squareSize))
                
                let targetColumn = boardModel.shouldFlipBoard ? square.column - columnOffset : square.column + columnOffset
                let targetRow = boardModel.shouldFlipBoard ? square.row + rowOffset : square.row - rowOffset
                
                boardModel.dropTarget = (targetRow, targetColumn)
                offset = value.translation
            }
            .onEnded { value in
                boardModel.selectedSquare = nil
                boardModel.dropTarget = nil
                isDragging = false
                boardModel.clearLegalMoveHighlights()
                
                guard let piece,
                      boardModel.interactionMode.canInteract(with: piece, turn: boardModel.turn)
                else {
                    withAnimation {
                        offset = .zero
                    }
                    return
                }
                
                let squareSize = boardModel.size / 8
                let columnOffset = Int(round(value.translation.width / squareSize))
                let rowOffset = Int(round(value.translation.height / squareSize))
                
                let targetColumn = boardModel.shouldFlipBoard ? square.column - columnOffset : square.column + columnOffset
                let targetRow = boardModel.shouldFlipBoard ? square.row + rowOffset : square.row - rowOffset

                guard (0...7).contains(targetColumn), (0...7).contains(targetRow) else {
                    withAnimation {
                        offset = .zero
                    }
                    return
                }
                
                let sourceSquare = "\(Character(UnicodeScalar(square.column + 97)!))\(square.row + 1)"
                let targetSquare = "\(Character(UnicodeScalar(targetColumn + 97)!))\(targetRow + 1)"
                
                let coordinateMove = "\(sourceSquare)\(targetSquare)"
                guard let move = try? Move(string: coordinateMove) else {
                    withAnimation {
                        offset = .zero
                    }
                    return
                }
                let isLegal = boardModel.game.legalMoves.contains(move)
                
                withAnimation {
                    offset = .zero
                }
                
                guard let selectedPiece = boardModel.game.position.board[square.row + square.column * 8]
                else { return }
                
                let requiresPromotionChoice = boardModel.requiresPromotionChoice(piece: selectedPiece, move: move)
                
                if !requiresPromotionChoice {
                    boardModel.reportMove(
                        move,
                        isLegal: isLegal,
                        sourceSquare: sourceSquare,
                        targetSquare: targetSquare,
                        coordinateMove: coordinateMove
                    )
                } else if ([PieceKind.queen, .rook, .bishop, .knight].contains { promotion in
                    boardModel.game.legalMoves.contains(Move(from: move.from, to: move.to, promotion: promotion))
                }) {
                    boardModel.presentPromotionPicker(piece: selectedPiece,
                                                      sourceSquare: sourceSquare,
                                                      targetSquare: targetSquare,
                                                      baseMove: move)
                } else {
                    boardModel.reportMove(
                        move,
                        isLegal: isLegal,
                        sourceSquare: sourceSquare,
                        targetSquare: targetSquare,
                        coordinateMove: coordinateMove
                    )
                }
            }
    }
}

private extension View {
    func chessBoardAccessibilityTraits(_ state: ChessBoardSquareAccessibilityState) -> some View {
        self
            .accessibilityAddTraits(state.isActivatable ? AccessibilityTraits.isButton : AccessibilityTraits())
            .accessibilityAddTraits(state.isSelected ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    @ViewBuilder
    func chessBoardAccessibilityAction(_ isEnabled: Bool, action: @escaping () -> Void) -> some View {
        if isEnabled {
            accessibilityAction {
                action()
            }
        } else {
            self
        }
    }
}

private func announceForAccessibility(_ message: String?) {
    guard let message, message.isEmpty == false else {
        return
    }

    #if canImport(UIKit)
    UIAccessibility.post(notification: .announcement, argument: message)
    #endif
}

private struct PieceImageView: View {
    var imageName: String
    var pieceSet: ChessPieceSet
    var fallback: String
    var fallbackColor: Color

    @ViewBuilder var body: some View {
        if let image = Self.bundledPNGImages[imageName] {
            renderedPieceImage(Image(decorative: image, scale: 1, orientation: .up))
        } else if Self.bundledPieceImageNames.contains(imageName) {
            renderedPieceImage(Image(imageName, bundle: .module))
        } else {
            Text(fallback)
                .foregroundStyle(fallbackColor)
                .font(.system(size: 18))
                .scaledToFit()
                .scaleEffect(0.85)
                .contentShape(Rectangle())
        }
    }

    private func renderedPieceImage(_ image: Image) -> some View {
        image
            .resizable()
            .interpolation(imageInterpolation)
            .scaledToFit()
            .scaleEffect(0.85)
            .contentShape(Rectangle())
    }

    private var imageInterpolation: Image.Interpolation {
        switch pieceSet.imageInterpolation {
        case .high:
            .high
        case .none:
            .none
        }
    }

    private static let bundledPieceImageNames = ChessPieceSet.bundledAssetNames

    private static let bundledPNGImages: [String: CGImage] = {
        Dictionary(uniqueKeysWithValues: ChessPieceSet.bundledAssetNames.compactMap { imageName in
            let subdirectory = "Pieces.xcassets/\(imageName).imageset"
            guard let url = Bundle.module.url(
                forResource: imageName,
                withExtension: "png",
                subdirectory: subdirectory
            ),
                let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                return nil
            }

            return (imageName, image)
        })
    }()
}
