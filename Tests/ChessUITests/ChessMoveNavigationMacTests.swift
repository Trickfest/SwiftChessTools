// Licensed under the MIT License. See LICENSE and NOTICE.md.

#if os(macOS)
import AppKit
import Observation
import SwiftUI
import Testing
import ChessUI

@MainActor
@Suite(.serialized) struct ChessMoveNavigationMacTests {
    @Test func nativeKeyboardShortcutsAreOptInAndCanBeDisabled() async throws {
        let model = NavigationKeyboardModel()
        let host = NSHostingView(rootView: NavigationKeyboardFixture(model: model))
        let window = NSWindow(
            contentRect: NSRect(x: 50, y: 50, width: 340, height: 100),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        try await settle()

        sendArrow(to: window, right: true)
        #expect(model.requests.isEmpty)
        #expect(model.ply == 2)

        model.shortcuts = true
        try await settle()
        sendArrow(to: window, right: true)
        try await settle()
        #expect(model.ply == 3)
        sendArrow(to: window, right: true, command: true)
        try await settle()
        #expect(model.ply == 4)
        let atEnd = model.requests
        sendArrow(to: window, right: true)
        #expect(model.requests == atEnd)
        sendArrow(to: window, right: false)
        try await settle()
        #expect(model.ply == 3)
        sendArrow(to: window, right: false, command: true)
        try await settle()
        #expect(model.ply == 0)
        #expect(model.requests == [3, 4, 3, 0])

        model.moveCount = 6
        model.callbackToken = 1
        try await settle()
        sendArrow(to: window, right: true, command: true)
        try await settle()
        #expect(model.ply == 6)
        #expect(model.callbackTokens.last == 1)
        for expectedPly in [5, 4, 3] {
            sendArrow(to: window, right: false)
            try await settle()
            #expect(model.ply == expectedPly)
        }
        for expectedPly in [4, 5, 6] {
            sendArrow(to: window, right: true)
            try await settle()
            #expect(model.ply == expectedPly)
        }

        model.ply = 2 // A caller reset, not a navigation action.
        try await settle()
        sendArrow(to: window, right: false)
        try await settle()
        #expect(model.ply == 1)
        model.disabled = true
        try await settle()
        let beforeDisabling = model.requests
        sendArrow(to: window, right: true)
        #expect(model.requests == beforeDisabling)
        model.disabled = false

        model.shortcuts = false
        try await settle()
        sendArrow(to: window, right: true, command: true)
        #expect(model.ply == 1)
        #expect(model.requests == beforeDisabling)
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    private func sendArrow(to window: NSWindow, right: Bool, command: Bool = false) {
        let character = String(UnicodeScalar(right ? NSRightArrowFunctionKey : NSLeftArrowFunctionKey)!)
        let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero,
            modifierFlags: command ? [.command, .function, .numericPad] : [.function, .numericPad],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, characters: character, charactersIgnoringModifiers: character,
            isARepeat: false, keyCode: right ? 124 : 123
        )!
        _ = window.performKeyEquivalent(with: event)
    }
}

@MainActor @Observable private final class NavigationKeyboardModel {
    var ply = 2
    var shortcuts = false
    var moveCount = 4
    var disabled = false
    var callbackToken = 0
    var callbackTokens: [Int] = []
    var requests: [Int] = []
}

private struct NavigationKeyboardFixture: View {
    let model: NavigationKeyboardModel
    var body: some View {
        let token = model.callbackToken
        ChessMoveNavigationView(selectedPly: model.ply, moveCount: model.moveCount, keyboardShortcutsEnabled: model.shortcuts) {
            model.callbackTokens.append(token)
            model.requests.append($0)
            model.ply = $0
        }
        .buttonStyle(.bordered)
        .disabled(model.disabled)
        .padding(10)
    }
}
#endif
