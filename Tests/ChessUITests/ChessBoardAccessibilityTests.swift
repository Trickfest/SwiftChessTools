//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Testing

import ChessCore
@testable import ChessUI

@Test func boardSquareAccessibilityDescribesDefaultPosition() {
    let model = ChessBoardModel(fen: initialFEN)

    let whitePawn = model.accessibilityState(for: square("e2"))
    #expect(whitePawn.label == "White pawn, e2")
    #expect(whitePawn.hint == "Activate to select this piece.")
    #expect(whitePawn.isActivatable)
    #expect(whitePawn.isSelected == false)
    #expect(whitePawn.isLegalDestination == false)

    let emptySquare = model.accessibilityState(for: square("e4"))
    #expect(emptySquare.label == "Empty, e4")
    #expect(emptySquare.hint == "Empty square.")
    #expect(emptySquare.isActivatable == false)

    let blackPawn = model.accessibilityState(for: square("e7"))
    #expect(blackPawn.label == "Black pawn, e7, not side to move")
    #expect(blackPawn.hint == "Only White can move.")
    #expect(blackPawn.isActivatable == false)
}

@Test func boardSquareAccessibilityReportsSelectionAndLegalDestinations() {
    let model = ChessBoardModel(fen: initialFEN)

    let announcement = model.activate(square: square("e2"))

    #expect(announcement == "White pawn selected on e2. Legal moves: e3, e4.")
    #expect(model.selectedSquare == square("e2"))
    #expect(model.legalMoveSquares == [square("e3"), square("e4")])

    let source = model.accessibilityState(for: square("e2"))
    #expect(source.label == "White pawn, e2, selected")
    #expect(source.hint == "Activate to clear selection.")
    #expect(source.isActivatable)
    #expect(source.isSelected)

    let destination = model.accessibilityState(for: square("e4"))
    #expect(destination.label == "Empty, e4, legal destination")
    #expect(destination.hint == "Activate to move here.")
    #expect(destination.isActivatable)
    #expect(destination.isLegalDestination)

    let illegalDestination = model.accessibilityState(for: square("e5"))
    #expect(illegalDestination.label == "Empty, e5")
    #expect(illegalDestination.hint == "Activate to report this move attempt.")
    #expect(illegalDestination.isActivatable)
    #expect(illegalDestination.isLegalDestination == false)
}

@Test func boardSquareAccessibilityReportsCaptures() {
    let model = ChessBoardModel(fen: "4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1")

    #expect(model.activate(square: square("e4")) == "White pawn selected on e4. Legal moves: d5, e5.")

    let capture = model.accessibilityState(for: square("d5"))
    #expect(capture.label == "Black pawn, d5, legal capture")
    #expect(capture.hint == "Activate to capture on this square.")
    #expect(capture.isLegalDestination)
    #expect(capture.isCaptureDestination)

    let quietMove = model.accessibilityState(for: square("e5"))
    #expect(quietMove.label == "Empty, e5, legal destination")
    #expect(quietMove.hint == "Activate to move here.")
    #expect(quietMove.isLegalDestination)
    #expect(quietMove.isCaptureDestination == false)
}

@Test func boardSquareAccessibilityKeepsLegalSpeechWhenVisualHighlightsAreDisabled() {
    let model = ChessBoardModel(fen: initialFEN, showsLegalMoveHighlights: false)

    #expect(model.activate(square: square("e2")) == "White pawn selected on e2. Legal moves: e3, e4.")
    #expect(model.legalMoveSquares.isEmpty)

    let destination = model.accessibilityState(for: square("e4"))
    #expect(destination.label == "Empty, e4, legal destination")
    #expect(destination.hint == "Activate to move here.")
    #expect(destination.isLegalDestination)
}

@Test func boardSquareAccessibilityRespectsReadOnlyMode() {
    let model = ChessBoardModel(fen: initialFEN, interactionMode: .readOnly)

    let state = model.accessibilityState(for: square("e2"))
    #expect(state.label == "White pawn, e2")
    #expect(state.hint == "Read-only board.")
    #expect(state.isActivatable == false)
    #expect(model.activate(square: square("e2")) == nil)
    #expect(model.selectedSquare == nil)
}

@Test func boardSquareAccessibilityRespectsLegalMovesOnlyMode() {
    let model = ChessBoardModel(fen: initialFEN, interactionMode: .legalMovesOnly)
    var attempts = [ChessBoardMoveAttempt]()
    model.onMove = { attempts.append($0) }

    #expect(model.activate(square: square("e2")) == "White pawn selected on e2. Legal moves: e3, e4.")

    let illegalDestination = model.accessibilityState(for: square("e5"))
    #expect(illegalDestination.hint == "Not a legal destination. Activate to clear selection.")
    #expect(illegalDestination.isActivatable)

    #expect(model.activate(square: square("e5")) == "Selection cleared. Not a legal move.")
    #expect(model.selectedSquare == nil)
    #expect(attempts.isEmpty)
}

@Test func boardSquareAccessibilityReportsIllegalAttemptsWhenConfigured() throws {
    let model = ChessBoardModel(fen: initialFEN, interactionMode: .reportsIllegalAttempts)
    var attempts = [ChessBoardMoveAttempt]()
    model.onMove = { attempts.append($0) }

    #expect(model.activate(square: square("e2")) == "White pawn selected on e2. Legal moves: e3, e4.")
    #expect(model.activate(square: square("e5")) == "Illegal move e2 to e5 requested.")

    let attempt = try #require(attempts.first)
    #expect(attempt.coordinateMove == "e2e5")
    #expect(attempt.isLegal == false)
    #expect(model.selectedSquare == nil)
}

@Test func boardSquareAccessibilityAllowsEitherSideInFreeSetupMode() {
    let model = ChessBoardModel(fen: initialFEN, interactionMode: .freeSetup)

    let state = model.accessibilityState(for: square("e7"))
    #expect(state.label == "Black pawn, e7")
    #expect(state.hint == "Activate to select this piece.")
    #expect(state.isActivatable)

    #expect(model.activate(square: square("e7")) == "Black pawn selected on e7. No legal moves.")
    #expect(model.selectedSquare == square("e7"))
}

@Test func boardSquareAccessibilityPresentsPromotionChoice() {
    let model = ChessBoardModel(fen: "7k/4P3/8/8/8/8/8/4K3 w - - 0 1")

    #expect(model.activate(square: square("e7")) == "White pawn selected on e7. Legal moves: e8.")

    let promotionTarget = model.accessibilityState(for: square("e8"))
    #expect(promotionTarget.label == "Empty, e8, legal destination")
    #expect(promotionTarget.hint == "Activate to move here.")
    #expect(promotionTarget.isLegalDestination)

    #expect(model.activate(square: square("e8")) == "Choose promotion piece.")
    #expect(model.isPromotionPickerPresented)
    #expect(model.promotionSourceSquare == "e7")
    #expect(model.promotionTargetSquare == "e8")
}

@Test func boardSquareAccessibilityCanClearSelection() {
    let model = ChessBoardModel(fen: initialFEN)

    #expect(model.activate(square: square("e2")) == "White pawn selected on e2. Legal moves: e3, e4.")
    #expect(model.activate(square: square("e2")) == "Selection cleared.")

    #expect(model.selectedSquare == nil)
    #expect(model.legalMoveSquares.isEmpty)
}

@Test func boardSquareAccessibilityReportsPiecesWithNoLegalDestinations() {
    let model = ChessBoardModel(fen: initialFEN)

    #expect(model.activate(square: square("d1")) == "White queen selected on d1. No legal moves.")
    #expect(model.selectedSquare == square("d1"))
    #expect(model.legalMoveSquares.isEmpty)
}

@Test func boardSquareAccessibilityWaitsForMoveAnimations() {
    let model = ChessBoardModel(fen: initialFEN)
    model.movingPiece = (
        piece: Piece(kind: .pawn, color: .white),
        from: square("e2"),
        to: square("e4")
    )

    let state = model.accessibilityState(for: square("e2"))
    #expect(state.label == "White pawn, e2")
    #expect(state.hint == "Wait for the current move animation to finish.")
    #expect(state.isActivatable == false)
    #expect(model.activate(square: square("e2")) == nil)
}

private func square(_ coordinate: String) -> BoardSquare {
    let file = "abcdefgh".firstIndex(of: coordinate.first!)!.utf16Offset(in: "abcdefgh")
    let rank = Int(String(coordinate.last!))!
    return BoardSquare(row: rank - 1, column: file)
}
