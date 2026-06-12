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

struct ContentView: View {
    var body: some View {
        WorkbenchView()
            .frame(minWidth: 820, minHeight: 560)
            .preferredColorScheme(.light)
    }
}

private struct WorkbenchView: View {
    private static let startingPosition = "5k2/1P2bn2/8/8/8/3Q4/3K4/8 w - - 0 1"
    private let moveRecordBuilder = ChessMoveRecordBuilder()

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var size: CGFloat = 360
    @State private var fen = Self.startingPosition
    @State private var didCopyFEN = false
    @State private var pieceSet = ChessPieceSet.artDecoMonochrome
    @State private var boardTheme = ChessBoardTheme.artDecoMonochrome
    @State private var evaluationSample = WorkbenchEvaluationSample.whiteEdge
    @State private var evaluationPlacement = WorkbenchEvaluationPlacement.leading
    @State private var evaluationWhiteSide = ChessEvaluationBarWhiteSide.bottom
    @State private var evaluationMaximumCentipawns = Double(ChessEvaluationBarDisplayState.defaultMaximumCentipawns)
    @State private var showsEvaluationLabel = true
    @State private var moveListLayout = ChessMoveListLayout.vertical
    @State private var showsMoveListScrollIndicators = false
    @State private var moveRecords: [ChessMoveRecord] = []
    @State private var selectedMovePly: Int?

    @State private var boardModel = ChessBoardModel(
        fen: startingPosition,
        perspective: .white,
        boardTheme: .artDecoMonochrome,
        pieceSet: .artDecoMonochrome
    )

    private var isResetDisabled: Bool {
        boardModel.fen == Self.startingPosition && fen == Self.startingPosition
    }

    private var evaluationMaximumCentipawnsValue: Int {
        max(1, Int(evaluationMaximumCentipawns.rounded()))
    }

    private var evaluationDisplayState: ChessEvaluationBarDisplayState {
        ChessEvaluationBarDisplayState(
            evaluation: evaluationSample.evaluation,
            maximumCentipawns: evaluationMaximumCentipawnsValue
        )
    }

    private var moveListScrollIndicatorVisibility: ScrollIndicatorVisibility {
        showsMoveListScrollIndicators ? .automatic : .hidden
    }

    var body: some View {
        HStack(spacing: 0) {
            boardPane

            Divider()

            inspectorPane
                .frame(width: 300)
        }
        .background {
            LinearGradient(
                colors: [
                    Color(white: 0.97),
                    Color(white: 0.92),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var boardPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chess Workbench")
                        .font(.title2.weight(.semibold))

                    Text("ChessCore + ChessUI")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Spacer(minLength: 0)

            boardStage
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var boardView: some View {
        ChessBoardView(model: boardModel)
            .onMove { move, isLegal, _, _, _, promotion in
                let appliedMove = promotion.map {
                    Move(from: move.from, to: move.to, promotion: $0)
                } ?? move
                handleBoardMove(move: appliedMove, isLegal: isLegal)
            }
    }

    private var boardStage: some View {
        Group {
            switch evaluationPlacement {
            case .leading:
                HStack(alignment: .bottom, spacing: 10) {
                    evaluationBar
                        .frame(width: 24, height: boardCardSide)
                    boardColumn
                }

            case .trailing:
                HStack(alignment: .bottom, spacing: 10) {
                    boardColumn
                    evaluationBar
                        .frame(width: 24, height: boardCardSide)
                }

            case .top:
                VStack(spacing: 10) {
                    evaluationBar
                        .frame(width: boardCardSide, height: 24)
                    boardColumn
                }

            case .bottom:
                VStack(spacing: 10) {
                    boardColumn
                    evaluationBar
                        .frame(width: boardCardSide, height: 24)
                }
            }
        }
    }

    private var boardColumn: some View {
        VStack(spacing: 10) {
            if moveListLayout == .horizontal {
                horizontalMovesStrip
            }

            boardCard
        }
    }

    private var horizontalMovesStrip: some View {
        ChessMoveListView(
            records: moveRecords,
            selectedPly: selectedMovePly,
            title: nil,
            layout: .horizontal,
            scrollIndicatorVisibility: moveListScrollIndicatorVisibility
        ) { record in
            selectedMovePly = record.ply
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: boardCardSide, height: 38)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.68))

                Color.clear
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Horizontal move list strip")
                    .accessibilityIdentifier("Workbench.horizontalMoveListStrip")
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        }
    }

    private var boardCard: some View {
        boardView
            .frame(width: size, height: size)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.76))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
    }

    private var boardCardSide: CGFloat {
        size + 28
    }

    private var evaluationBar: some View {
        ChessEvaluationBar(
            evaluation: evaluationSample.evaluation,
            orientation: evaluationPlacement.orientation,
            whiteSide: evaluationWhiteSide,
            maximumCentipawns: evaluationMaximumCentipawnsValue,
            showsLabel: showsEvaluationLabel
        )
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("Workbench.evaluationBar")
        .accessibilityLabel("Workbench evaluation")
        .accessibilityValue(evaluationDisplayState.accessibilityValue)
    }

    private var inspectorPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                inspectorHeader
                actionSection
                positionSection
                if moveListLayout == .vertical {
                    movesSection
                }
                displaySection
                evaluationSection
            }
            .padding(18)
        }
        .background(.ultraThinMaterial)
    }

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Workbench")
                .font(.headline)
            Text("Manual controls")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionSection: some View {
        WorkbenchSection("Actions") {
            VStack(spacing: 9) {
                Button {
                    boardModel.togglePromotionPicker()
                } label: {
                    Label(
                        boardModel.isPromotionPickerPresented ? "Hide Promotion" : "Show Promotion",
                        systemImage: boardModel.isPromotionPickerPresented ? "chevron.down.square" : "chevron.up.square"
                    )
                }
                .buttonStyle(WorkbenchButtonStyle(isProminent: boardModel.isPromotionPickerPresented))
                .accessibilityIdentifier("Workbench.showPromotion")

                Button {
                    boardModel.hint("d3", for: 1)
                } label: {
                    Label("Show d3 Marker", systemImage: "scope")
                }
                .buttonStyle(WorkbenchButtonStyle())
                .accessibilityIdentifier("Workbench.showD3Marker")

                Button {
                    withAnimation {
                        fen = Self.startingPosition
                        boardModel.setFEN(Self.startingPosition)
                        clearMoveRecords()
                    }
                } label: {
                    Label("Reset Position", systemImage: "arrow.counterclockwise")
                }
                .disabled(isResetDisabled)
                .buttonStyle(WorkbenchButtonStyle())
                .accessibilityIdentifier("Workbench.resetPosition")

                Button {
                    copyFENToPasteboard()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: didCopyFEN ? "checkmark" : "doc.on.doc")
                            .frame(width: 16, height: 16)

                        ZStack(alignment: .leading) {
                            Text("Copy FEN")
                                .opacity(didCopyFEN ? 0 : 1)

                            Text("Copied FEN")
                                .opacity(didCopyFEN ? 1 : 0)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(didCopyFEN ? "Copied FEN" : "Copy FEN")
                }
                .buttonStyle(WorkbenchButtonStyle())
                .accessibilityIdentifier("Workbench.copyFEN")
            }
        }
    }

    private var positionSection: some View {
        WorkbenchSection("Position") {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $fen)
                    .font(.system(.callout, design: .monospaced))
                    .frame(minHeight: 92)
                    .padding(7)
                    .scrollContentBackground(.hidden)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.7))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(showError ? 0.36 : 0.14), lineWidth: 1)
                    }
                    .onChange(of: fen) { _, newValue in
                        updatePosition(with: newValue)
                    }
                    .onChange(of: boardModel.fen) { _, newValue in
                        fen = newValue
                    }
                    .accessibilityLabel("FEN")
                    .accessibilityIdentifier("Workbench.fenEditor")

                Text(showError ? errorMessage : "FEN accepted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("Workbench.fenStatus")
            }
        }
    }

    private var displaySection: some View {
        WorkbenchSection("Display") {
            VStack(alignment: .leading, spacing: 10) {
                displayPickerRow("Pieces") {
                    WorkbenchMenuPicker(
                        title: "Pieces",
                        options: ChessPieceSet.availableSets,
                        selection: $pieceSet,
                        displayName: { $0.displayName },
                        accessibilityIdentifier: "Workbench.pieceSetPicker"
                    )
                    .frame(width: 200, height: 24)
                    .onChange(of: pieceSet) { _, newValue in
                        boardModel.pieceSet = newValue
                        boardModel.size = size
                    }
                    .accessibilityValue(pieceSet.displayName)
                }

                displayPickerRow("Board") {
                    WorkbenchMenuPicker(
                        title: "Board",
                        options: ChessBoardTheme.availableThemes,
                        selection: $boardTheme,
                        displayName: { $0.displayName },
                        accessibilityIdentifier: "Workbench.boardThemePicker"
                    )
                    .frame(width: 200, height: 24)
                    .onChange(of: boardTheme) { _, newValue in
                        boardModel.boardTheme = newValue
                        boardModel.size = size
                    }
                    .accessibilityValue(boardTheme.displayName)
                }

                displayPickerRow("Moves") {
                    WorkbenchMenuPicker(
                        title: "Move list",
                        options: ChessMoveListLayout.allCases,
                        selection: $moveListLayout,
                        displayName: { $0.workbenchDisplayName },
                        accessibilityIdentifier: "Workbench.moveListLayoutPicker"
                    )
                    .frame(width: 200, height: 24)
                    .accessibilityValue(moveListLayout.workbenchDisplayName)
                }

                Toggle("Scroll bars", isOn: $showsMoveListScrollIndicators)
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("Workbench.moveListScrollBarsToggle")
                    .accessibilityValue(showsMoveListScrollIndicators ? "On" : "Off")

                HStack {
                    Text("Board size")
                    Spacer()
                    Text("\(Int(size))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("Workbench.boardSizeValue")
                }
                .font(.callout)

                Slider(value: $size, in: 220...420, step: 10)
                    .onChange(of: size) { _, newValue in
                        boardModel.size = newValue
                    }
            }
        }
    }

    private var movesSection: some View {
        WorkbenchSection("Moves") {
            ChessMoveListView(
                records: moveRecords,
                selectedPly: selectedMovePly,
                title: nil,
                layout: .vertical,
                scrollIndicatorVisibility: moveListScrollIndicatorVisibility
            ) { record in
                selectedMovePly = record.ply
            }
            .frame(height: 150)
        }
    }

    private var evaluationSection: some View {
        WorkbenchSection("Evaluation") {
            VStack(alignment: .leading, spacing: 10) {
                displayPickerRow("Value") {
                    WorkbenchMenuPicker(
                        title: "Evaluation",
                        options: WorkbenchEvaluationSample.allCases,
                        selection: $evaluationSample,
                        displayName: { $0.displayName },
                        accessibilityIdentifier: "Workbench.evaluationSamplePicker"
                    )
                    .frame(width: 200, height: 24)
                    .accessibilityValue(evaluationSample.displayName)
                }

                displayPickerRow("Place") {
                    WorkbenchMenuPicker(
                        title: "Evaluation placement",
                        options: WorkbenchEvaluationPlacement.allCases,
                        selection: $evaluationPlacement,
                        displayName: { $0.displayName },
                        accessibilityIdentifier: "Workbench.evaluationPlacementPicker"
                    )
                    .frame(width: 200, height: 24)
                    .onChange(of: evaluationPlacement) { _, newValue in
                        if !evaluationWhiteSide.isCompatible(with: newValue.orientation) {
                            evaluationWhiteSide = newValue.defaultWhiteSide
                        }
                    }
                    .accessibilityValue(evaluationPlacement.displayName)
                }

                displayPickerRow("White") {
                    WorkbenchMenuPicker(
                        title: "White side",
                        options: evaluationPlacement.compatibleWhiteSides,
                        selection: $evaluationWhiteSide,
                        displayName: { $0.displayName },
                        accessibilityIdentifier: "Workbench.evaluationWhiteSidePicker"
                    )
                    .frame(width: 200, height: 24)
                    .accessibilityValue(evaluationWhiteSide.displayName)
                }

                Toggle("Show label", isOn: $showsEvaluationLabel)
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("Workbench.evaluationLabelToggle")

                HStack {
                    Text("Max cp")
                    Spacer()
                    Text("\(evaluationMaximumCentipawnsValue)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("Workbench.evaluationScaleValue")
                }
                .font(.callout)

                Slider(value: $evaluationMaximumCentipawns, in: 200...1_200, step: 100)
                    .accessibilityIdentifier("Workbench.evaluationScaleSlider")

                Text(evaluationDisplayState.accessibilityValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("Workbench.evaluationStatus")
            }
        }
    }

    private func displayPickerRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(width: 44, alignment: .leading)

            Spacer(minLength: 0)

            content()
        }
        .font(.callout)
    }

    private func updatePosition(with newValue: String) {
        if newValue == boardModel.fen {
            showError = false
            errorMessage = ""
            return
        }

        if !FENValidator.isValid(newValue) {
            showError = true
            errorMessage = "Invalid FEN notation."
            return
        }

        showError = false
        errorMessage = ""
        boardModel.setFEN(newValue)
        clearMoveRecords()
    }

    private func handleBoardMove(move: Move, isLegal: Bool) {
        guard isLegal else {
            return
        }

        do {
            try appendMoveRecord(for: move)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            return
        }

        boardModel.game.apply(move: move)
        boardModel.setFEN(
            FENSerializer().fen(from: boardModel.game.position),
            animatedMove: move
        )
    }

    private func appendMoveRecord(for move: Move) throws {
        let record = try moveRecordBuilder.record(
            for: move,
            in: boardModel.game,
            ply: moveRecords.count + 1
        )
        moveRecords.append(record)
        selectedMovePly = record.ply
    }

    private func clearMoveRecords() {
        moveRecords.removeAll()
        selectedMovePly = nil
    }

    private func copyFENToPasteboard() {
        let currentFEN = FENSerializer().fen(from: boardModel.game.position)
        guard WorkbenchPasteboard.copy(currentFEN) else { return }

        didCopyFEN = true
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            didCopyFEN = false
        }
    }
}

private extension ChessMoveListLayout {
    var workbenchDisplayName: String {
        switch self {
        case .vertical:
            "Vertical"
        case .horizontal:
            "Horizontal"
        }
    }
}

private enum WorkbenchEvaluationSample: String, CaseIterable, Identifiable {
    case unavailable
    case equal
    case whiteEdge
    case blackEdge
    case whiteWinning
    case blackWinning
    case whiteMate
    case blackMate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unavailable:
            "Unavailable"
        case .equal:
            "Equal"
        case .whiteEdge:
            "White +0.9"
        case .blackEdge:
            "Black -1.4"
        case .whiteWinning:
            "White +6.2"
        case .blackWinning:
            "Black -6.2"
        case .whiteMate:
            "White mate in 3"
        case .blackMate:
            "Black mate in 2"
        }
    }

    var evaluation: ChessEvaluation {
        switch self {
        case .unavailable:
            .unavailable
        case .equal:
            .centipawns(0)
        case .whiteEdge:
            .centipawns(85)
        case .blackEdge:
            .centipawns(-135)
        case .whiteWinning:
            .centipawns(620)
        case .blackWinning:
            .centipawns(-620)
        case .whiteMate:
            .mate(moves: 3, side: .white)
        case .blackMate:
            .mate(moves: 2, side: .black)
        }
    }
}

private enum WorkbenchEvaluationPlacement: String, CaseIterable, Identifiable {
    case leading
    case trailing
    case top
    case bottom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leading:
            "Left"
        case .trailing:
            "Right"
        case .top:
            "Top"
        case .bottom:
            "Bottom"
        }
    }

    var orientation: ChessEvaluationBarOrientation {
        switch self {
        case .leading, .trailing:
            .vertical
        case .top, .bottom:
            .horizontal
        }
    }

    var compatibleWhiteSides: [ChessEvaluationBarWhiteSide] {
        switch orientation {
        case .vertical:
            [.bottom, .top]
        case .horizontal:
            [.leading, .trailing]
        }
    }

    var defaultWhiteSide: ChessEvaluationBarWhiteSide {
        ChessEvaluationBarWhiteSide.defaultSide(for: orientation)
    }
}

private struct WorkbenchMenuPicker<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let displayName: (Option) -> String
    let accessibilityIdentifier: String
    var width: CGFloat = 200

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    HStack {
                        if option == selection {
                            Image(systemName: "checkmark")
                        }

                        Text(displayName(option))
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(displayName(selection))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 9)
            .frame(width: width, height: 24)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.56))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(accessibilityIdentifier)
            .accessibilityLabel(title)
            .accessibilityValue(displayName(selection))
        }
        .buttonStyle(.plain)
    }
}

private struct WorkbenchSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            content
        }
        .padding(13)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.58))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct WorkbenchButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(isProminent ? .semibold : .medium))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 38)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.55)
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return Color.black.opacity(0.38)
        }

        return isProminent ? .white : Color.black.opacity(0.82)
    }

    private var borderColor: Color {
        if !isEnabled {
            return Color.black.opacity(0.12)
        }

        return isProminent ? Color.black.opacity(0.72) : Color.black.opacity(0.16)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return Color.white.opacity(0.36)
        }

        if isProminent {
            return Color.black.opacity(isPressed ? 0.72 : 0.86)
        }

        return Color.white.opacity(isPressed ? 0.54 : 0.82)
    }
}

#Preview {
    ContentView()
}
