//
// ChessUI provides reusable SwiftUI chess board views and supporting helpers.
//
// See NOTICE.md for upstream attribution and license details.
//
// Copyright (C) 2025, Oğuzhan Eroğlu (https://meowingcat.io)
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import SwiftUI

import ChessCore

/// FEN for an empty board with White to move.
public let emptyFEN = "8/8/8/8/8/8/8/8 w - - 0 1"

/// FEN for the standard chess starting position.
public let initialFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

/// Callback invoked when a user attempts a move on `ChessBoardView`.
public typealias ChessBoardMoveHandler = (
    _ move: Move,
    _ isLegal: Bool,
    _ sourceSquare: String,
    _ targetSquare: String,
    _ coordinateMove: String,
    _ promotion: PieceKind?
) -> Void

/// A zero-based board square used by ChessUI state and highlighting APIs.
public struct BoardSquare: Identifiable, Hashable {
    /// Zero-based rank index, where `0` is rank 1.
    public var row: Int

    /// Zero-based file index, where `0` is file a.
    public var column: Int

    /// Creates a board square from zero-based row and column indexes.
    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
    
    public var id: String {
        "\(row),\(column)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.row == rhs.row && lhs.column == rhs.column
    }
    
    public static func != (lhs: Self, rhs: Self) -> Bool {
        lhs.row != rhs.row || lhs.column != rhs.column
    }
}

/// Observable state model for `ChessBoardView`.
///
/// Use this model to load positions, control board perspective and highlights,
/// apply move-feedback animations, and inspect the underlying `Game`. Invalid
/// FEN input is reported through `fenError` instead of crashing.
@Observable
public class ChessBoardModel {
    private static func emptyPosition() -> Position {
        try! FENSerializer().position(from: emptyFEN)
    }

    /// Current board position as FEN.
    ///
    /// Assigning invalid FEN leaves the current position unchanged and stores
    /// the parser error in `fenError`.
    public var fen: String {
        get { FENSerializer().fen(from: game.position) }
        set {
            setFEN(newValue)
        }
    }
    
    /// Current rendered board size in points.
    public var size: CGFloat = 0

    /// Board colors used for squares and markers.
    public var colorScheme: ChessBoardColorScheme = .light

    /// Side displayed at the bottom of the board.
    public var perspective: PieceColor

    /// Side to move in the current game state.
    public var turn: PieceColor { game.position.state.turn }

    /// When `true`, move callbacks identify illegal attempted moves but the UI
    /// does not apply them automatically.
    public var validatesMoves: Bool = false

    /// Allows selecting and moving pieces that do not belong to the side to
    /// move.
    public var allowsOpponentMoves = false

    /// Controls whether the board shows a non-interactive waiting overlay.
    public var isWaiting = false

    /// Currently selected square, if any.
    public var selectedSquare: BoardSquare?

    /// Squares currently highlighted as hints.
    public var hintedSquares: Set<BoardSquare> = []

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
    /// recent move. The default is a translucent gold similar to common online
    /// chess boards.
    public var lastMoveHighlightColor: Color = Color(red: 1.0, green: 0.82, blue: 0.20, opacity: 0.55)

    /// Source and destination squares for the most recent move passed through
    /// `setFEN(_:animatedMove:)`. Direct `fen` assignment clears this value
    /// because a raw FEN string does not reliably identify the move that
    /// produced it.
    public private(set) var lastMoveSquares: (from: BoardSquare, to: BoardSquare)?
    
    /// Controls presentation of the built-in promotion picker.
    public var isPromotionPickerPresented = false

    /// Underlying chess game backing the board.
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
    /// - Parameters:
    ///   - fen: Initial board position.
    ///   - perspective: Side displayed at the bottom of the board.
    ///   - colorScheme: Board and marker colors.
    ///   - allowsOpponentMoves: Allows dragging pieces that do not belong to the
    ///     side to move.
    ///   - showsLegalMoveHighlights: Shows legal destination markers while a piece
    ///     is selected or dragged.
    ///   - moveAnimationDuration: Duration, in seconds, for move animations
    ///     triggered by `setFEN(_:animatedMove:)`.
    ///   - showsLastMoveHighlight: Keeps the source and destination squares of
    ///     the last move highlighted after `setFEN(_:animatedMove:)`.
    ///   - lastMoveHighlightColor: Overlay color used for the last-move source and
    ///     destination squares.
    public init(fen: String = emptyFEN,
                perspective: PieceColor = .white,
                colorScheme: ChessBoardColorScheme = .light,
                allowsOpponentMoves: Bool = false,
                showsLegalMoveHighlights: Bool = true,
                moveAnimationDuration: Double = 0.45,
                showsLastMoveHighlight: Bool = true,
                lastMoveHighlightColor: Color = Color(red: 1.0, green: 0.82, blue: 0.20, opacity: 0.55))
    {
        do {
            self.game = Game(position: try FENSerializer().position(from: fen))
            self.fenError = nil
        } catch {
            self.game = Game(position: Self.emptyPosition())
            self.fenError = error
        }
        self.perspective = perspective
        self.colorScheme = colorScheme
        self.allowsOpponentMoves = allowsOpponentMoves
        self.showsLegalMoveHighlights = showsLegalMoveHighlights
        self.moveAnimationDuration = max(0, moveAnimationDuration)
        self.showsLastMoveHighlight = showsLastMoveHighlight
        self.lastMoveHighlightColor = lastMoveHighlightColor
    }
    
    public var onMove: ChessBoardMoveHandler = { _, _, _, _, _, _ in }
    
    public var dropTarget: (row: Int, column: Int)?
    
    /// Replaces the current board position and, when `animatedMove` is supplied,
    /// animates the moved piece from source to destination and highlights both
    /// squares.
    ///
    /// Use this method for interactive play and engine replies. Directly
    /// assigning `fen` is still supported for arbitrary position loading, but
    /// direct assignment clears move-specific animation and highlight state
    /// because a FEN string alone does not identify the source square.
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
    
    public func deselect() {
        selectedSquare = nil
        legalMoveSquares.removeAll()
    }
    
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
    
    public func clearLegalMoveHighlights() {
        legalMoveSquares.removeAll()
    }
    
    public func hint(_ square: BoardSquare) {
        hintedSquares.insert(square)
    }
    
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
    
    public func hint(row: Int, column: Int) {
        hint(BoardSquare(row: row, column: column))
    }
    
    public func hint(_ squares: [BoardSquare]) {
        for square in squares {
            hint(square)
        }
    }
    
    public func hint(_ squares: [String]) {
        for square in squares {
            hint(square)
        }
    }
    
    public func clearHint() {
        hintedSquares.removeAll()
    }
    
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
    
    public func presentPromotionPicker(piece: Piece, sourceSquare: String, targetSquare: String, baseMove: Move) {
        promotionPiece = piece
        promotionSourceSquare = sourceSquare
        promotionTargetSquare = targetSquare
        promotionBaseMove = baseMove
        
        withAnimation(.bouncy) {
            isPromotionPickerPresented = true
        }
    }
    
    public func dismissPromotionPicker() {
        promotionPiece = nil
        promotionSourceSquare = nil
        promotionTargetSquare = nil
        promotionBaseMove = nil
        
        withAnimation(.bouncy) {
            isPromotionPickerPresented = false
        }
    }
    
    public func togglePromotionPicker() {
        withAnimation(.bouncy) {
            isPromotionPickerPresented.toggle()
        }
    }
    
    public func requiresPromotionChoice(piece: Piece, move: Move) -> Bool {
        guard piece.kind == .pawn else { return false }
        return move.to.rank == (piece.color == .white ? 7 : 0)
    }
    
    public func showWaitingOverlay() {
        withAnimation(.bouncy) {
            isWaiting = true
        }
    }
    
    public func hideWaitingOverlay() {
        withAnimation(.bouncy) {
            isWaiting = false
        }
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

/// SwiftUI chessboard view backed by `ChessBoardModel`.
///
/// The view renders the board, pieces, markers, move gestures, promotion UI,
/// and move callbacks. It does not apply moves by itself; callers update the
/// model after deciding whether a reported move should change the game state.
public struct ChessBoardView: View {
    /// State model rendered and mutated by the board.
    public var model: ChessBoardModel
    
    @Namespace private var animation
    
    /// Creates a chessboard view for the provided model.
    public init(model: ChessBoardModel) {
        self.model = model
    }

    private var boardModel: ChessBoardModel { model }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                lastMoveHighlightsView
                    .allowsHitTesting(false)
                labelsView
                    .allowsHitTesting(false)
                squaresView
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
                            
                            boardModel.onMove(
                                promotedMove,
                                isLegal,
                                sourceSquare,
                                targetSquare,
                                promotedCoordinateMove,
                                promotion)
                            
                            boardModel.dismissPromotionPicker()
                        } label: {
                            let imageName = "\(boardModel.perspective == PieceColor.white ? "w" : "b")\(String(describing: piece).uppercased())"
                            
                            ZStack {
                                PieceImageView(imageName: imageName,
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
                
                Rectangle()
                    .fill(isLightSquare ? boardModel.colorScheme.light : boardModel.colorScheme.dark)
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
        
        return Text("\(displayRow + 1)")
            .font(.system(size: labelSize))
            .foregroundColor(boardModel.colorScheme.label)
            .frame(width: labelSize, height: squareSize, alignment: .center)
            .position(
                x: labelSize / 2 + 2,
                y: boardModel.size - (CGFloat(row) * squareSize + squareSize - 10)
            )
    }
    
    func columnLabelView(column: Int) -> some View {
        let displayColumn = boardModel.shouldFlipBoard ? 7 - column : column
        let labelSize = boardModel.size / 32
        let squareSize = boardModel.size / 8
        
        return Text(["a", "b", "c", "d", "e", "f", "g", "h"][displayColumn])
            .font(.system(size: labelSize))
            .foregroundColor(boardModel.colorScheme.label)
            .frame(width: squareSize, height: labelSize, alignment: .center)
            .position(
                x: (CGFloat(column) * squareSize + squareSize) - 8,
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
                    .fill(boardModel.colorScheme.legalMove)
                    .frame(width: boardModel.size / 24, height: boardModel.size / 24)
                    .position(position(for: square))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Legal move \(coordinate(for: square))")
                    .accessibilityIdentifier("ChessUI.legalMove.\(coordinate(for: square))")
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
    
    /// Registers a callback for attempted board moves.
    public func onMove(_ callback: @escaping ChessBoardMoveHandler) -> ChessBoardView {
        boardModel.onMove = callback
        return self
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
        .modifier {
            if let dropTarget = boardModel.dropTarget,
               !isDragging &&
                dropTarget.row == row && dropTarget.column == column
            {
                $0.overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(boardModel.colorScheme.selected, lineWidth: 3.5)
                }
            } else if isSelected {
                $0.overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(boardModel.colorScheme.selected, lineWidth: 3.5)
                }
            } else if isHinted {
                $0.overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(boardModel.colorScheme.hinted, lineWidth: 3.5)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Hint \(coordinate)")
                        .accessibilityIdentifier("ChessUI.hint.\(coordinate)")
                }
            } else { $0 }
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
        ZStack {
            if let piece {
                let imageName = "\(piece.color == PieceColor.white ? "w" : "b")\(String(describing: piece).uppercased())"
                
                PieceImageView(imageName: imageName,
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
        .onTapGesture(perform: onTapGesture)
        .gesture(dragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("ChessUI.square.\(coordinate)")
    }

    private var coordinate: String {
        let file = Character(UnicodeScalar(square.column + 97)!)
        return "\(file)\(square.row + 1)"
    }

    private var accessibilityLabel: String {
        guard let piece else {
            return "Empty \(coordinate)"
        }

        let color = piece.color == .white ? "White" : "Black"
        let kind: String
        switch piece.kind {
        case .king:
            kind = "king"
        case .queen:
            kind = "queen"
        case .rook:
            kind = "rook"
        case .bishop:
            kind = "bishop"
        case .knight:
            kind = "knight"
        case .pawn:
            kind = "pawn"
        }
        return "\(color) \(kind) \(coordinate)"
    }
    
    func onTapGesture() {
        if boardModel.movingPiece != nil {
            return
        }
        
        if let piece, piece.color != boardModel.turn && boardModel.selectedSquare == nil {
            return
        }
        
        if isSelected {
            boardModel.selectedSquare = nil
            boardModel.clearLegalMoveHighlights()
        } else if piece != nil && boardModel.selectedSquare == nil {
            boardModel.selectedSquare = isSelected ? nil: BoardSquare(row: square.row, column: square.column)
            if boardModel.selectedSquare != nil {
                boardModel.updateLegalMoveHighlights(for: BoardSquare(row: square.row, column: square.column))
            }
        } else if let selectedSquare = boardModel.selectedSquare {
            let sourceRow = selectedSquare.row
            let sourceColumn = selectedSquare.column
            
            let sourceSquare = "\(Character(UnicodeScalar(sourceColumn + 97)!))\(sourceRow + 1)"
            let targetSquare = "\(Character(UnicodeScalar(square.column + 97)!))\(square.row + 1)"
            
            let coordinateMove = "\(sourceSquare)\(targetSquare)"
            boardModel.deselect()
            boardModel.clearLegalMoveHighlights()

            guard let move = try? Move(string: coordinateMove) else {
                return
            }

            let isLegal = boardModel.game.legalMoves.contains(move)
            
            guard let selectedPiece = boardModel.game.position.board[selectedSquare.row + selectedSquare.column * 8]
            else { return }
            
            let requiresPromotionChoice = boardModel.requiresPromotionChoice(piece: selectedPiece, move: move)
            
            if !requiresPromotionChoice {
                if !boardModel.validatesMoves || isLegal {
                    boardModel.onMove(move, isLegal, sourceSquare, targetSquare, coordinateMove, nil)
                }
            } else if ([PieceKind.queen, .rook, .bishop, .knight].contains { promotion in
                boardModel.game.legalMoves.contains(Move(from: move.from, to: move.to, promotion: promotion))
            }) {
                boardModel.presentPromotionPicker(piece: selectedPiece,
                                                  sourceSquare: sourceSquare,
                                                  targetSquare: targetSquare,
                                                  baseMove: move)
            } else if !boardModel.validatesMoves || isLegal {
                boardModel.onMove(move, isLegal, sourceSquare, targetSquare, coordinateMove, nil)
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if boardModel.movingPiece != nil {
                    return
                }
                
                if boardModel.selectedSquare != nil {
                    boardModel.deselect()
                }
                
                if let piece, piece.color != boardModel.turn,
                   !boardModel.allowsOpponentMoves && piece.color != boardModel.perspective
                {
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
                
                if let piece, piece.color != boardModel.turn,
                   !boardModel.allowsOpponentMoves && piece.color != boardModel.perspective {
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
                    if !boardModel.validatesMoves || isLegal {
                        boardModel.onMove(move, isLegal, sourceSquare, targetSquare, coordinateMove, nil)
                    }
                } else if ([PieceKind.queen, .rook, .bishop, .knight].contains { promotion in
                    boardModel.game.legalMoves.contains(Move(from: move.from, to: move.to, promotion: promotion))
                }) {
                    boardModel.presentPromotionPicker(piece: selectedPiece,
                                                      sourceSquare: sourceSquare,
                                                      targetSquare: targetSquare,
                                                      baseMove: move)
                } else if !boardModel.validatesMoves || boardModel.game.legalMoves.contains(move) {
                    boardModel.onMove(move, isLegal, sourceSquare, targetSquare, coordinateMove, nil)
                }
            }
    }
}

private struct PieceImageView: View {
    var imageName: String
    var fallback: String
    var fallbackColor: Color

    var body: some View {
        if Self.bundledPieceImageNames.contains(imageName) {
            Image(imageName, bundle: .module)
                .resizable()
                .scaledToFit()
                .scaleEffect(0.85)
                .contentShape(Rectangle())
        } else {
            Text(fallback)
                .foregroundStyle(fallbackColor)
                .font(.system(size: 18))
                .scaledToFit()
                .scaleEffect(0.85)
                .contentShape(Rectangle())
        }
    }

    private static let bundledPieceImageNames: Set<String> = [
        "wK", "wQ", "wR", "wB", "wN", "wP",
        "bK", "bQ", "bR", "bB", "bN", "bP",
    ]
}

public extension View {
    func modifier<ModifiedContent: View>(@ViewBuilder content: (_ content: Self) -> ModifiedContent) -> ModifiedContent {
        content(self)
    }
}
