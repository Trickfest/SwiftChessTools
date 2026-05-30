import SwiftUI
import AppKit

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

    @Bindable private var boardModel = ChessBoardModel(
        fen: startingPosition,
        perspective: .white,
        colorScheme: .light
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

            ChessBoardView(model: boardModel)
                .onMove { move, isLegal, _, _, coordinateMove, _ in
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

                Button {
                    boardModel.hint("d3", for: 1)
                } label: {
                    Label("Show d3 Marker", systemImage: "scope")
                }
                .buttonStyle(WorkbenchButtonStyle())

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

                Text(showError ? errorMessage : "FEN accepted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var displaySection: some View {
        WorkbenchSection("Display") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Board size")
                    Spacer()
                    Text("\(Int(size))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.callout)

                Slider(value: $size, in: 220...420, step: 10)
            }
        }
    }

    private func updatePosition(with newValue: String) {
        if !FENValidator.isValid(newValue) {
            showError = true
            errorMessage = "Invalid FEN notation."
            return
        }

        showError = false
        errorMessage = ""
        boardModel.setFEN(newValue)
    }

    private func copyFENToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(FENSerializer().fen(from: boardModel.game.position), forType: .string)

        didCopyFEN = true
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            didCopyFEN = false
        }
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
