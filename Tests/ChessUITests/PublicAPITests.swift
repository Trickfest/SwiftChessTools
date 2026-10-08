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
import SwiftUI

import ChessUI
import ChessCore

@MainActor
@Test func historyPresentationAPIsArePubliclyUsable() throws {
    let timeline = try GameTimeline()
    let model = ChessBoardModel()
    model.setGame(try timeline.game(atPly: 0))
    let list = ChessMoveListView(records: timeline.moveRecords, selectedPly: 0,
                                scrollBehavior: .selectedMove) { _ in }
    #expect(type(of: list) == ChessMoveListView.self)
    #expect(ChessMoveListScrollBehavior.allCases == [.latestMove, .selectedMove])
}

@MainActor
@Test func moveNavigationAPIsArePubliclyUsable() {
    let view = ChessMoveNavigationView(selectedPly: 0, moveCount: 4) { _ in }
    let shortcuts = ChessMoveNavigationView(selectedPly: 2, moveCount: 4, keyboardShortcutsEnabled: true) { _ in }
    #expect(type(of: view) == ChessMoveNavigationView.self)
    #expect(type(of: shortcuts) == ChessMoveNavigationView.self)
    #expect(ChessMoveNavigationState(selectedPly: 1, moveCount: 4).destination(for: .end) == 4)
}

@MainActor
@Test func moveListAPIsArePubliclyUsable() {
    #expect(ChessMoveListLayout.allCases == [.vertical, .horizontal])

    let hiddenIndicatorMoveList = ChessMoveListView(
        records: [],
        layout: .horizontal,
        scrollIndicatorVisibility: .hidden
    )
    #expect(type(of: hiddenIndicatorMoveList) == ChessMoveListView.self)
}

@Test func coordinateLabelPlacementAPIsArePubliclyUsable() {
    #expect(ChessBoardCoordinateLabelPlacement.allCases == [.inside, .outside])
    #expect(ChessBoardCoordinateLabelPlacement.inside.id == "inside")
    #expect(ChessBoardCoordinateLabelPlacement.outside.id == "outside")

    let existingInitializerModel = ChessBoardModel(fen: initialFEN)
    #expect(existingInitializerModel.coordinateLabelPlacement == .inside)

    let outsideLabelsModel = ChessBoardModel(
        fen: initialFEN,
        coordinateLabelPlacement: .outside,
        showsCoordinateLabels: false
    )
    #expect(outsideLabelsModel.showsCoordinateLabels == false)
    #expect(outsideLabelsModel.coordinateLabelPlacement == .outside)
}

@Test func boardArrowAPIsArePubliclyUsable() {
    let customStyle = ChessBoardArrowStyle(
        red: -1,
        green: 0.5,
        blue: 2,
        lineWidth: -4,
        opacity: 3
    )

    #expect(customStyle.red == 0)
    #expect(customStyle.green == 0.5)
    #expect(customStyle.blue == 1)
    #expect(customStyle.lineWidth == 1)
    #expect(customStyle.opacity == 1)
    #expect(ChessBoardArrowStyle.primarySuggestion.lineWidth > ChessBoardArrowStyle.secondarySuggestion.lineWidth)
    #expect(ChessBoardArrowStyle.secondarySuggestion.lineWidth > ChessBoardArrowStyle.tertiarySuggestion.lineWidth)

    let arrow = ChessBoardArrow(
        from: BoardSquare(row: 1, column: 4),
        to: BoardSquare(row: 3, column: 4),
        style: customStyle,
        label: "Best move"
    )

    #expect(arrow.from == BoardSquare(row: 1, column: 4))
    #expect(arrow.to == BoardSquare(row: 3, column: 4))
    #expect(arrow.style == customStyle)
    #expect(arrow.label == "Best move")
    #expect(ChessBoardArrow(from: "e2", to: "e4") != nil)
    #expect(ChessBoardArrow(from: "i2", to: "e4") == nil)
}
