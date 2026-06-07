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

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var size: CGFloat = 360
    @State private var fen = Self.startingPosition
    @State private var didCopyFEN = false
    @State private var pieceSet = ChessPieceSet.artDecoMonochrome
    @State private var boardTheme = ChessBoardTheme.artDecoMonochrome

    @State private var boardModel = ChessBoardModel(
        fen: startingPosition,
        perspective: .white,
        boardTheme: .artDecoMonochrome,
        pieceSet: .artDecoMonochrome
    )

    private var isResetDisabled: Bool {
        boardModel.fen == Self.startingPosition && fen == Self.startingPosition
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
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var boardView: some View {
        ChessBoardView(model: boardModel)
            .onMove { move, isLegal, _, _, coordinateMove, _ in
                handleBoardMove(move: move, isLegal: isLegal, coordinateMove: coordinateMove)
            }
    }

    private var inspectorPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                inspectorHeader
                actionSection
                positionSection
                displaySection
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
    }

    private func handleBoardMove(move: Move, isLegal: Bool, coordinateMove: String) {
        print("Move: FEN: \(boardModel.fen) - coordinate move: \(coordinateMove)")

        if !isLegal {
            print("Illegal move: \(coordinateMove)")
            return
        }

        boardModel.game.apply(move: move)
        boardModel.setFEN(
            FENSerializer().fen(from: boardModel.game.position),
            animatedMove: move
        )
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

private struct WorkbenchMenuPicker<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let displayName: (Option) -> String
    let accessibilityIdentifier: String

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
            .frame(width: 200, height: 24)
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
