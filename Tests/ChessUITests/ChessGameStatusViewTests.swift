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

import ChessCore
import ChessUI

@Test func gameStatusDisplayStateDescribesOngoingTurns() {
    let white = ChessGameStatusDisplayState(
        status: .ongoing(drawClaims: []),
        turn: .white
    )
    let black = ChessGameStatusDisplayState(
        status: .ongoing(drawClaims: []),
        turn: .black
    )
    let unknown = ChessGameStatusDisplayState(status: .ongoing(drawClaims: []))

    #expect(white.text == "White to move")
    #expect(white.accessibilityValue == "White to move")
    #expect(black.text == "Black to move")
    #expect(unknown.text == "Game ongoing")
    #expect(white.drawClaims.isEmpty)
}

@Test func gameStatusDisplayStateDescribesDrawClaimsInDeterministicOrder() {
    let fiftyMove = ChessGameStatusDisplayState(
        status: .ongoing(drawClaims: [.fiftyMoveRule]),
        turn: .white
    )
    let bothClaims = ChessGameStatusDisplayState(
        status: .ongoing(drawClaims: [.threefoldRepetition, .fiftyMoveRule]),
        turn: .black
    )

    #expect(fiftyMove.text == "White to move. Draw claim available: fifty-move rule")
    #expect(fiftyMove.drawClaims == [.fiftyMoveRule])
    #expect(
        bothClaims.text
            == "Black to move. Draw claims available: fifty-move rule and threefold repetition"
    )
    #expect(bothClaims.drawClaims == [.fiftyMoveRule, .threefoldRepetition])
}

@Test func gameStatusDisplayStateDescribesTerminalStatuses() {
    #expect(
        ChessGameStatusDisplayState(status: .checkmate(winner: .white)).text
            == "White wins by checkmate"
    )
    #expect(
        ChessGameStatusDisplayState(status: .checkmate(winner: .black)).text
            == "Black wins by checkmate"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.stalemate)).text
            == "Draw by stalemate"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.insufficientMaterial)).text
            == "Draw by insufficient material"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.deadPosition)).text
            == "Draw by dead position"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.seventyFiveMoveRule)).text
            == "Draw by seventy-five-move rule"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.fivefoldRepetition)).text
            == "Draw by fivefold repetition"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.fiftyMoveRule)).text
            == "Draw by fifty-move rule"
    )
    #expect(
        ChessGameStatusDisplayState(status: .draw(.threefoldRepetition)).text
            == "Draw by threefold repetition"
    )
}

@Test func gameStatusDisplayStateProvidesDrawClaimButtonLabels() {
    #expect(
        ChessGameStatusDisplayState.drawClaimButtonLabel(for: .fiftyMoveRule)
            == "Claim fifty-move draw"
    )
    #expect(
        ChessGameStatusDisplayState.drawClaimButtonLabel(for: .threefoldRepetition)
            == "Claim threefold repetition draw"
    )
}

@MainActor
@Test func gameStatusViewAPIsArePubliclyUsable() {
    let passiveView = ChessGameStatusView(
        status: .ongoing(drawClaims: []),
        turn: .white
    )
    let claimView = ChessGameStatusView(
        status: .ongoing(drawClaims: [.fiftyMoveRule]),
        turn: .white
    ) { _ in }

    #expect(type(of: passiveView) == ChessGameStatusView.self)
    #expect(type(of: claimView) == ChessGameStatusView.self)
}
