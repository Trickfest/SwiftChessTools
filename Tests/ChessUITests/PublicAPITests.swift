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
