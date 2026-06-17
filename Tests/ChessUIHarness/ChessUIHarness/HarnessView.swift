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
    @State private var model = ChessBoardModel(fen: initialFEN, moveAnimationDuration: 0.08)
    @State private var lastMove = "No moves yet"
    @State private var currentFEN = initialFEN

    var body: some View {
        VStack(spacing: 10) {
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

            Text(lastMove)
                .font(.caption)
                .accessibilityIdentifier("Harness.lastMove")

            Text(currentFEN)
                .font(.caption2.monospaced())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("Harness.fen")

            ChessBoardView(model: model)
                .frame(maxWidth: 380, maxHeight: 380)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 18)
        .onAppear {
            configureModel()
        }
    }

    private func configureModel() {
        model.interactionMode = .legalMovesOnly
        model.showsLegalMoveHighlights = true
        model.showsLastMoveHighlight = true
        model.moveAnimationDuration = 0.08
        model.onMove = handleMove
        currentFEN = model.fen
    }

    private func resetBoard(perspective: PieceColor) {
        model.perspective = perspective
        model.fen = initialFEN
        model.clearHint()
        model.clearLegalMoveHighlights()
        model.dismissPromotionPicker()
        lastMove = "No moves yet"
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
