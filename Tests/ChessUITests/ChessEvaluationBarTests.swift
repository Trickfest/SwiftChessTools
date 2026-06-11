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

@Test func centipawnEvaluationsMapToWhiteFractions() {
    let equal = ChessEvaluationBarDisplayState(evaluation: .centipawns(0), maximumCentipawns: 800)
    let whiteAdvantage = ChessEvaluationBarDisplayState(evaluation: .centipawns(400), maximumCentipawns: 800)
    let blackAdvantage = ChessEvaluationBarDisplayState(evaluation: .centipawns(-400), maximumCentipawns: 800)

    #expect(equal.whiteFraction == 0.5)
    #expect(whiteAdvantage.whiteFraction == 0.75)
    #expect(blackAdvantage.whiteFraction == 0.25)
}

@Test func centipawnEvaluationsClampToVisualRange() {
    let whiteWinning = ChessEvaluationBarDisplayState(evaluation: .centipawns(1_200), maximumCentipawns: 800)
    let blackWinning = ChessEvaluationBarDisplayState(evaluation: .centipawns(-1_200), maximumCentipawns: 800)

    #expect(whiteWinning.whiteFraction == 1)
    #expect(blackWinning.whiteFraction == 0)
}

@Test func centipawnEvaluationsUseCompactPawnLabels() {
    let whiteEdge = ChessEvaluationBarDisplayState(evaluation: .centipawns(85))
    let blackEdge = ChessEvaluationBarDisplayState(evaluation: .centipawns(-135))
    let equal = ChessEvaluationBarDisplayState(evaluation: .centipawns(0))

    #expect(whiteEdge.label == "+0.9")
    #expect(whiteEdge.accessibilityValue == "White advantage 0.9 pawns")
    #expect(blackEdge.label == "-1.4")
    #expect(blackEdge.accessibilityValue == "Black advantage 1.4 pawns")
    #expect(equal.label == "0.0")
    #expect(equal.accessibilityValue == "Equal evaluation")
}

@Test func mateEvaluationsSaturateTheBarAndUseMateLabels() {
    let whiteMate = ChessEvaluationBarDisplayState(evaluation: .mate(moves: 3, side: .white))
    let blackMate = ChessEvaluationBarDisplayState(evaluation: .mate(moves: 2, side: .black))

    #expect(whiteMate.whiteFraction == 1)
    #expect(whiteMate.label == "M3")
    #expect(whiteMate.accessibilityValue == "White mate in 3")

    #expect(blackMate.whiteFraction == 0)
    #expect(blackMate.label == "-M2")
    #expect(blackMate.accessibilityValue == "Black mate in 2")
}

@Test func unavailableEvaluationRendersNeutralState() {
    let state = ChessEvaluationBarDisplayState(evaluation: .unavailable)

    #expect(state.whiteFraction == 0.5)
    #expect(state.label == "--")
    #expect(state.accessibilityValue == "Evaluation unavailable")
}

@Test func invalidMaximumCentipawnsStillProducesSafeOutput() {
    let state = ChessEvaluationBarDisplayState(evaluation: .centipawns(1), maximumCentipawns: 0)

    #expect(state.whiteFraction == 1)
    #expect(state.label == "+0.0")
}

@Test func whiteSideCompatibilityFollowsBarOrientation() {
    #expect(ChessEvaluationBarWhiteSide.top.isCompatible(with: .vertical))
    #expect(ChessEvaluationBarWhiteSide.bottom.isCompatible(with: .vertical))
    #expect(ChessEvaluationBarWhiteSide.leading.isCompatible(with: .horizontal))
    #expect(ChessEvaluationBarWhiteSide.trailing.isCompatible(with: .horizontal))

    #expect(ChessEvaluationBarWhiteSide.top.isCompatible(with: .horizontal) == false)
    #expect(ChessEvaluationBarWhiteSide.leading.isCompatible(with: .vertical) == false)
    #expect(ChessEvaluationBarWhiteSide.defaultSide(for: .vertical) == .bottom)
    #expect(ChessEvaluationBarWhiteSide.defaultSide(for: .horizontal) == .leading)
}
