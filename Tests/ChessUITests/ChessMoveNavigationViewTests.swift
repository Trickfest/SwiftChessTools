// Licensed under the MIT License. See LICENSE and NOTICE.md.

import SwiftUI
import Testing
@testable import ChessUI

@Suite struct ChessMoveNavigationViewTests {
    @Test func emptyStartMiddleEndDestinations() {
        let actions = ChessMoveNavigationAction.allCases
        #expect(actions == [.start, .previous, .next, .end])
        let cases: [(Int, Int, [Int?])] = [
            (0, 0, [nil, nil, nil, nil]),
            (0, 4, [nil, nil, 1, 4]),
            (2, 4, [0, 1, 3, 4]),
            (4, 4, [0, 3, nil, nil]),
            (0, 1, [nil, nil, 1, 1]),
            (1, 1, [0, 0, nil, nil])
        ]
        for (ply, count, expected) in cases {
            let state = ChessMoveNavigationState(selectedPly: ply, moveCount: count)
            #expect(state.isValid)
            #expect(actions.map { state.destination(for: $0) } == expected)
        }
    }

    @Test func invalidInputFailsClosedWithoutClampingOrOverflow() {
        for (ply, count) in [(-1, 4), (5, 4), (0, -1), (Int.min, Int.max), (Int.max, 0)] {
            let state = ChessMoveNavigationState(selectedPly: ply, moveCount: count)
            #expect(!state.isValid)
            #expect(state.selectedPly == ply)
            #expect(state.moveCount == count)
            #expect(ChessMoveNavigationAction.allCases.allSatisfy { state.destination(for: $0) == nil })
            #expect(state.accessibilityValue == "Move navigation unavailable")
        }
        let end = ChessMoveNavigationState(selectedPly: Int.max, moveCount: Int.max)
        #expect(end.destination(for: .next) == nil)
        #expect(end.destination(for: .previous) == Int.max - 1)
    }

    @Test func lineGrowthDoesNotChangeSelection() {
        let reviewing = ChessMoveNavigationState(selectedPly: 2, moveCount: 6)
        let grown = ChessMoveNavigationState(selectedPly: reviewing.selectedPly, moveCount: 7)
        #expect(grown.selectedPly == 2)
        #expect(grown.destination(for: .end) == 7)
        #expect(grown.destination(for: .next) == 3)
    }

    @Test func accessibilityDescribesSelectionAndActions() {
        #expect(ChessMoveNavigationState(selectedPly: 0, moveCount: 0).accessibilityValue == "No moves recorded")
        #expect(ChessMoveNavigationState(selectedPly: 0, moveCount: 4).accessibilityValue == "Starting position, 4 recorded moves")
        #expect(ChessMoveNavigationState(selectedPly: 2, moveCount: 4).accessibilityValue == "After 2 of 4 recorded moves")
        #expect(ChessMoveNavigationAction.allCases.map(\.title) == ["Position Start", "Previous Move", "Next Move", "Line End"])
        #expect(ChessMoveNavigationAction.allCases.allSatisfy { !$0.hint.isEmpty })
    }

    @Test func optInShortcutMappings() {
        #expect(ChessMoveNavigationAction.start.shortcut.key == .leftArrow)
        #expect(ChessMoveNavigationAction.start.shortcut.modifiers == .command)
        #expect(ChessMoveNavigationAction.previous.shortcut.key == .leftArrow)
        #expect(ChessMoveNavigationAction.previous.shortcut.modifiers == [])
        #expect(ChessMoveNavigationAction.next.shortcut.key == .rightArrow)
        #expect(ChessMoveNavigationAction.next.shortcut.modifiers == [])
        #expect(ChessMoveNavigationAction.end.shortcut.key == .rightArrow)
        #expect(ChessMoveNavigationAction.end.shortcut.modifiers == .command)
    }
}
