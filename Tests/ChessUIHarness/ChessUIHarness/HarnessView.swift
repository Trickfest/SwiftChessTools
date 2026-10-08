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
        if ProcessInfo.processInfo.environment["CHESS_UI_HARNESS_HISTORY"] == "1" {
            HistoryHarnessView()
        } else if ProcessInfo.processInfo.environment["CHESS_UI_HARNESS_NAVIGATION"] == "1" {
            NavigationHarnessView()
        } else {
            boardHarness
        }
    }

    private var boardHarness: some View {
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
                .onMove(handleMove)
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

            Button("Outside") {
                model.showsCoordinateLabels = true
                model.coordinateLabelPlacement = .outside
            }
            .accessibilityIdentifier("Harness.outsideCoordinates")

            Button("Promotion") {
                showPromotionScenario()
            }
            .accessibilityIdentifier("Harness.promotionScenario")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
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
        if let value = ProcessInfo.processInfo.environment["CHESS_UI_HARNESS_PIECE_SCALE"],
           let scale = Double(value) {
            model.pieceRenderingScaleOverrides[model.pieceSet] = CGFloat(scale)
        }
        model.interactionMode = interactionMode
        model.showsLegalMoveHighlights = true
        model.showsLastMoveHighlight = true
        model.moveAnimationDuration = 0.08
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

/// Package-level integration fixture, not production app policy.
private struct HistoryHarnessView: View {
    @State private var timeline = initialTimeline()
    @State private var selectedPly = 100
    @State private var alternate = false
    @State private var jumpOnDrag = false
    @State private var attempts = 0
    @State private var model = ChessBoardModel(moveAnimationDuration: 0)
    private var horizontal: Bool { ProcessInfo.processInfo.environment["HISTORY_HORIZONTAL"] == "1" }
    private var legacy: Bool { ProcessInfo.processInfo.environment["HISTORY_LEGACY"] == "1" }

    var body: some View {
        VStack(spacing: 12) {
            ChessBoardView(model: model)
                .onMove { _ in attempts += 1 }
                .frame(width: 180, height: 180)
            Text("Attempts \(attempts)")
                .accessibilityIdentifier("Harness.historyAttempts")
            Text("Ply \(selectedPly), count \(timeline.moveCount)")
                .accessibilityIdentifier("Harness.historyState")
            ChessMoveNavigationView(selectedPly: selectedPly, moveCount: timeline.moveCount, onSelectPly: select)
                .buttonStyle(.bordered)
            Group {
                if legacy {
                    // Exercise the unchanged initializer, not the new explicit policy.
                    ChessMoveListView(records: timeline.moveRecords, selectedPly: selectedPly,
                                      title: nil, layout: horizontal ? .horizontal : .vertical,
                                      onSelectRecord: { select($0.ply) })
                } else {
                    ChessMoveListView(records: timeline.moveRecords, selectedPly: selectedPly,
                                      title: nil, layout: horizontal ? .horizontal : .vertical,
                                      scrollBehavior: .selectedMove, onSelectRecord: { select($0.ply) })
                }
            }
            .frame(width: 320, height: horizontal ? 60 : 120)
            HStack {
                Button("One") { select(1) }
                Button("Middle") { select(50) }
                Button("Grow") {
                    let cycle = Self.cycle(count: timeline.moveCount + 1, alternate: alternate)
                    try! timeline.append(cycle.last!)
                }
                Button("Replace") {
                    alternate = true
                    try! timeline.replaceContinuation(afterPly: 0, with: Self.cycle(count: timeline.moveCount, alternate: true))
                    select(selectedPly)
                }
                Button("Reset") {
                    alternate = false
                    timeline = try! GameTimeline()
                    select(0)
                }
            }
            .buttonStyle(.bordered)
            Button("Jump on drag") { jumpOnDrag = true }
        }
        .frame(maxWidth: 340)
        .padding()
        .onAppear { select(legacy ? 1 : 100) }
        .onChange(of: model.dropTarget?.row) { _, row in
            if jumpOnDrag && row != nil {
                jumpOnDrag = false
                select(1)
            }
        }
    }

    private func select(_ ply: Int) {
        guard let displayed = try? timeline.game(atPly: ply) else { return }
        model.setGame(displayed)
        selectedPly = ply
    }

    private static func cycle(count: Int, alternate: Bool = false) -> [Move] {
        let moves = (alternate ? ["b1c3", "b8c6", "c3b1", "c6b8"] : ["g1f3", "g8f6", "f3g1", "f6g8"])
            .map { try! Move(string: $0) }
        return (0..<count).map { moves[$0 % 4] }
    }

    private static func initialTimeline() -> GameTimeline {
        let fullMoveNumber = Int(ProcessInfo.processInfo.environment["HISTORY_FULL_MOVE_NUMBER"] ?? "1") ?? 1
        let position = try! FENSerializer().position(from:
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 \(fullMoveNumber)")
        return try! GameTimeline(initialPosition: position, moves: cycle(count: 100))
    }
}

/// Isolated control fixture; deliberately has no board, timeline, or engine.
private struct NavigationHarnessView: View {
    @State private var ply = 0
    @State private var count = 4
    @State private var requests = 0
    @State private var lastRequest = -1
    @State private var acceptsRequests = true
    @State private var shortcuts = false
    @State private var text = ""
    @FocusState private var editing: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Navigation control")
            Text("Ply \(ply), count \(count), requests \(requests), last \(lastRequest)")
                .accessibilityIdentifier("Harness.navigationState")
            ChessMoveNavigationView(
                selectedPly: ply, moveCount: count,
                keyboardShortcutsEnabled: shortcuts && !editing
            ) {
                requests += 1
                lastRequest = $0
                if acceptsRequests { ply = $0 }
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .frame(maxWidth: 340)
            Toggle("Accept requests", isOn: $acceptsRequests)
                .accessibilityIdentifier("Harness.acceptNavigation")
            Toggle("Keyboard shortcuts", isOn: $shortcuts)
                .accessibilityIdentifier("Harness.navigationShortcuts")
            TextField("Keyboard editing check", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($editing)
                .accessibilityIdentifier("Harness.navigationEditor")
            HStack {
                Button("Empty") { ply = 0; count = 0 }
                Button("Invalid") { ply = -1 }
                Button("Grow") { count += 1 }
                Button("Reset") { ply = 0; count = 4; editing = false }
            }
        }
        .padding()
    }
}
