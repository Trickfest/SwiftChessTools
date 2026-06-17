//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import SwiftUI

import ChessCore
import ChessUI

struct HarnessView: View {
    private static let harnessMoveRecords: [ChessMoveRecord] = {
        do {
            return try ChessMoveRecordBuilder().records(
                initialPosition: FENSerializer().position(from: initialFEN),
                moves: [
                    Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e4")),
                    Move(from: Square(coordinate: "e7"), to: Square(coordinate: "e5")),
                    Move(from: Square(coordinate: "g1"), to: Square(coordinate: "f3")),
                ]
            )
        } catch {
            return []
        }
    }()

    @State private var model = ChessBoardModel(fen: initialFEN, moveAnimationDuration: 0.08)
    @State private var lastMove = "No moves yet"
    @State private var currentFEN = initialFEN
    @State private var interactionMode = ChessBoardInteractionMode.legalMovesOnly
    @State private var selectedPly: Int? = 2
    @State private var drawClaimResult = "No draw claim"

    var body: some View {
        VStack(spacing: 8) {
            primaryControls

            interactionModeControls

            Text("Mode: \(interactionMode.rawValue)")
                .font(.caption)
                .accessibilityIdentifier("Harness.interactionMode")

            Text(lastMove)
                .font(.caption)
                .accessibilityIdentifier("Harness.lastMove")

            Text(currentFEN)
                .font(.caption2.monospaced())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("Harness.fen")

            ChessBoardView(model: model)
                .frame(width: 340, height: 340)
                .padding(.horizontal, 12)

            accessibilityCoverageSurface
        }
        .padding(.vertical, 12)
        .onAppear {
            configureModel()
        }
    }

    private var primaryControls: some View {
        HStack(spacing: 8) {
            Button("Reset") {
                resetBoard(perspective: model.perspective)
            }
            .accessibilityIdentifier("Harness.reset")

            Button("Black") {
                resetBoard(perspective: .black)
            }
            .accessibilityIdentifier("Harness.blackPerspective")

            Button("Promotion") {
                showPromotionScenario()
            }
            .accessibilityIdentifier("Harness.promotionScenario")
        }
        .buttonStyle(.bordered)
    }

    private var interactionModeControls: some View {
        HStack(spacing: 6) {
            Button("Read") {
                setInteractionMode(.readOnly)
            }
            .accessibilityIdentifier("Harness.mode.readOnly")

            Button("Legal") {
                setInteractionMode(.legalMovesOnly)
            }
            .accessibilityIdentifier("Harness.mode.legalMovesOnly")

            Button("Report") {
                setInteractionMode(.reportsIllegalAttempts)
            }
            .accessibilityIdentifier("Harness.mode.reportsIllegalAttempts")

            Button("Setup") {
                setInteractionMode(.freeSetup)
            }
            .accessibilityIdentifier("Harness.mode.freeSetup")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var accessibilityCoverageSurface: some View {
        VStack(spacing: 6) {
            ChessGameStatusView(
                status: .ongoing(drawClaims: [.fiftyMoveRule, .threefoldRepetition]),
                turn: .white
            ) { claim in
                drawClaimResult = claimedDrawText(for: claim)
            }
            .frame(maxWidth: 340, alignment: .leading)

            Text(drawClaimResult)
                .font(.caption2)
                .accessibilityIdentifier("Harness.drawClaim")

            ChessEvaluationBar(
                evaluation: .mate(moves: 2, side: .black),
                orientation: .horizontal
            )
            .frame(width: 220, height: 24)

            ChessMoveListView(
                records: Self.harnessMoveRecords,
                selectedPly: selectedPly,
                title: "Harness moves",
                layout: .horizontal
            ) { record in
                selectedPly = record.ply
            }
            .frame(width: 340, height: 58)
        }
        .padding(.horizontal, 12)
    }

    private func configureModel() {
        model.interactionMode = interactionMode
        model.showsLegalMoveHighlights = true
        model.showsLastMoveHighlight = true
        model.moveAnimationDuration = 0.08
        model.onMove = handleMove
        currentFEN = model.fen
    }

    private func setInteractionMode(_ mode: ChessBoardInteractionMode) {
        interactionMode = mode
        configureModel()
    }

    private func resetBoard(perspective: PieceColor) {
        model.perspective = perspective
        model.fen = initialFEN
        model.clearHint()
        model.clearLegalMoveHighlights()
        model.dismissPromotionPicker()
        lastMove = "No moves yet"
        drawClaimResult = "No draw claim"
        configureModel()
    }

    private func showPromotionScenario() {
        model.perspective = .white
        model.fen = "7k/4P3/8/8/8/8/8/4K3 w - - 0 1"
        model.clearHint()
        model.clearLegalMoveHighlights()
        model.dismissPromotionPicker()
        lastMove = "No moves yet"
        configureModel()
    }

    private func claimedDrawText(for claim: GameDrawClaim) -> String {
        switch claim {
        case .fiftyMoveRule:
            return "Claimed fifty-move rule"
        case .threefoldRepetition:
            return "Claimed threefold repetition"
        }
    }

    private func handleMove(_ attempt: ChessBoardMoveAttempt) {
        guard attempt.isLegal else {
            lastMove = "Rejected \(attempt.coordinateMove)"
            return
        }

        model.game.apply(move: attempt.move)
        let fen = FENSerializer().fen(from: model.game.position)
        model.setFEN(fen, animatedMove: attempt.move)
        currentFEN = fen
        lastMove = attempt.coordinateMove
    }
}
