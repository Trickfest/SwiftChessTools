// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
// Licensed under the MIT License. See LICENSE and NOTICE.md.

import SwiftUI

/// An intent to navigate a caller-owned recorded move line.
public enum ChessMoveNavigationAction: String, CaseIterable, Sendable {
    case start, previous, next, end

    /// VoiceOver label and keyboard-shortcut title for the action.
    public var title: String {
        switch self {
        case .start: "Position Start"
        case .previous: "Previous Move"
        case .next: "Next Move"
        case .end: "Line End"
        }
    }

    /// Explanation of the action, also used for pointer help.
    public var hint: String {
        switch self {
        case .start: "Return to the starting position"
        case .previous: "Move backward by one recorded move"
        case .next: "Move forward by one recorded move"
        case .end: "Jump to the furthest recorded move"
        }
    }

    var symbol: String {
        switch self {
        case .start: "backward.end.fill"
        case .previous: "backward.fill"
        case .next: "forward.fill"
        case .end: "forward.end.fill"
        }
    }

    var shortcut: KeyboardShortcut {
        switch self {
        case .start: KeyboardShortcut(.leftArrow, modifiers: .command)
        case .previous: KeyboardShortcut(.leftArrow, modifiers: [])
        case .next: KeyboardShortcut(.rightArrow, modifiers: [])
        case .end: KeyboardShortcut(.rightArrow, modifiers: .command)
        }
    }
}

/// Immutable navigation availability derived from a caller's selection and line.
///
/// Ply zero is the starting position and `moveCount` is the recorded end.
/// Invalid input disables all actions rather than silently repairing app state.
public struct ChessMoveNavigationState: Equatable, Sendable {
    public let selectedPly: Int
    public let moveCount: Int

    public init(selectedPly: Int, moveCount: Int) {
        self.selectedPly = selectedPly
        self.moveCount = moveCount
    }

    /// Whether the selection identifies a position in the recorded line.
    public var isValid: Bool {
        moveCount >= 0 && selectedPly >= 0 && selectedPly <= moveCount
    }

    /// Returns the requested destination, or nil for invalid or boundary input.
    /// A nil destination means the corresponding button is disabled.
    public func destination(for action: ChessMoveNavigationAction) -> Int? {
        guard isValid else { return nil }
        switch action {
        case .start: return selectedPly > 0 ? 0 : nil
        case .previous: return selectedPly > 0 ? selectedPly - 1 : nil
        case .next: return selectedPly < moveCount ? selectedPly + 1 : nil
        case .end: return selectedPly < moveCount ? moveCount : nil
        }
    }

    /// Description of the currently supplied selection for assistive technology.
    public var accessibilityValue: String {
        guard isValid else { return "Move navigation unavailable" }
        guard moveCount > 0 else { return "No moves recorded" }
        guard selectedPly > 0 else { return "Starting position, \(moveCount) recorded moves" }
        return "After \(selectedPly) of \(moveCount) recorded moves"
    }
}

/// Four native buttons for start, previous, next, and recorded-line end.
///
/// The view is controlled by its caller. It reports a destination ply without
/// changing selection, games, engines, or playback policy. It can be used with
/// GameTimeline or any other linear history. Invalid input disables all buttons.
///
/// Buttons use the environment's button style and tint, with a minimum 44-point
/// label width and 48-point label height. Apply `.buttonStyle`, `.tint`, or a
/// custom ButtonStyle and an outer frame to match the consuming app.
///
/// Shortcuts are off by default. When enabled, arrows step and Command-arrows
/// jump to boundaries. SwiftUI shortcuts are window/scene-wide, not local to
/// keyboard focus: callers should enable them only for the active board and
/// disable them during text editing or use their own app commands instead.
public struct ChessMoveNavigationView: View {
    private let state: ChessMoveNavigationState
    private let keyboardShortcutsEnabled: Bool
    private let onSelectPly: (Int) -> Void

    /// Creates a caller-controlled navigation bar.
    public init(
        selectedPly: Int,
        moveCount: Int,
        keyboardShortcutsEnabled: Bool = false,
        onSelectPly: @escaping (Int) -> Void
    ) {
        self.state = ChessMoveNavigationState(selectedPly: selectedPly, moveCount: moveCount)
        self.keyboardShortcutsEnabled = keyboardShortcutsEnabled
        self.onSelectPly = onSelectPly
    }

    public var body: some View {
        HStack(spacing: 10) {
            ForEach(ChessMoveNavigationAction.allCases, id: \.self) { action in
                NavigationButton(
                    action: action, destination: state.destination(for: action),
                    keyboardShortcutsEnabled: keyboardShortcutsEnabled,
                    onSelectPly: onSelectPly
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Move navigation")
        .accessibilityValue(state.accessibilityValue)
        .accessibilityIdentifier("ChessUI.moveNavigation")
    }
}

private struct NavigationButton: View {
    @State private var invocation = NavigationInvocation()
    let action: ChessMoveNavigationAction
    let destination: Int?
    let keyboardShortcutsEnabled: Bool
    let onSelectPly: (Int) -> Void

    var body: some View {
        // Native shortcut registration can retain an earlier Button action even
        // when its label and disabled state update. Keep button identity/focus
        // stable, but route every invocation through the latest caller inputs.
        // This reference is deliberately not observable: it stores no selection
        // and updating the callback does not trigger another view update.
        let invocation = invocation
        invocation.perform = { [destination, onSelectPly] in
            if let destination { onSelectPly(destination) }
        }
        return Button {
            invocation.perform()
        } label: {
            Label(action.title, systemImage: action.symbol)
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(minWidth: 44, maxWidth: .infinity, minHeight: 48)
                .contentShape(Rectangle())
        }
        .disabled(destination == nil)
        .keyboardShortcut(keyboardShortcutsEnabled ? action.shortcut : nil)
        .help("\(action.title): \(action.hint)")
        .accessibilityLabel(action.title)
        .accessibilityHint(action.hint)
        .accessibilityIdentifier("ChessUI.moveNavigation.\(action.rawValue)")
    }
}

@MainActor private final class NavigationInvocation {
    var perform: () -> Void = {}
}
