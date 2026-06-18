//
// SwiftChessTools provides reusable chess rules, notation, SwiftUI board UI,
// and UCI command/parsing helpers.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Testing

import ChessCore
import ChessUCI

@Test func identificationAndHandshakeLinesParseToTypedOutput() {
    #expect(
        UCIParser().parse("id name Stockfish 17")
            == .id(UCIIdentification(rawLine: "id name Stockfish 17", kind: .name, value: "Stockfish 17"))
    )
    #expect(
        UCIParser().parse("id author The Stockfish developers")
            == .id(UCIIdentification(
                rawLine: "id author The Stockfish developers",
                kind: .author,
                value: "The Stockfish developers"
            ))
    )
    #expect(UCIParser().parse("uciok") == .uciOK)
    #expect(UCIParser().parse("readyok") == .readyOK)
}

@Test func optionLinesParseCommonOptionTypes() {
    let spin = expectOption("option name Hash type spin default 16 min 1 max 33554432")
    let check = expectOption("option name Ponder type check default false")
    let button = expectOption("option name Clear Hash type button")
    let string = expectOption("option name SyzygyPath type string default /tb/one:/tb/two")

    #expect(spin.name == "Hash")
    #expect(spin.type == .spin)
    #expect(spin.defaultValue == "16")
    #expect(spin.min == 1)
    #expect(spin.max == 33_554_432)
    #expect(check.name == "Ponder")
    #expect(check.type == .check)
    #expect(check.defaultValue == "false")
    #expect(button.name == "Clear Hash")
    #expect(button.type == .button)
    #expect(button.defaultValue == nil)
    #expect(string.name == "SyzygyPath")
    #expect(string.type == .string)
    #expect(string.defaultValue == "/tb/one:/tb/two")
}

@Test func optionLinesParseComboVarsAndUnknownTypes() {
    let combo = expectOption(
        "option name Style type combo default Normal var Solid var Normal var Risky"
    )
    let unknown = expectOption("option name Future Mode type custom default something")

    #expect(combo.name == "Style")
    #expect(combo.type == .combo)
    #expect(combo.defaultValue == "Normal")
    #expect(combo.vars == ["Solid", "Normal", "Risky"])
    #expect(unknown.name == "Future Mode")
    #expect(unknown.type == .unknown("custom"))
    #expect(unknown.defaultValue == "something")
}

@Test func malformedOptionLinesStillPreserveRecognizedFields() {
    let option = expectOption("option name Missing Numbers type spin min nope max 100")

    #expect(option.name == "Missing Numbers")
    #expect(option.type == .spin)
    #expect(option.min == nil)
    #expect(option.max == 100)
}

@Test func copyProtectionAndRegistrationLinesParseStatuses() {
    #expect(UCIParser().parse("copyprotection checking") == .copyProtection(.checking))
    #expect(UCIParser().parse("copyprotection ok") == .copyProtection(.ok))
    #expect(UCIParser().parse("copyprotection error") == .copyProtection(.error))
    #expect(UCIParser().parse("copyprotection weird status") == .copyProtection(.unknown("weird status")))
    #expect(UCIParser().parse("registration checking") == .registration(.checking))
    #expect(UCIParser().parse("registration ok") == .registration(.ok))
    #expect(UCIParser().parse("registration error") == .registration(.error))
    #expect(UCIParser().parse("registration expired") == .registration(.unknown("expired")))
}

@Test func bestMoveParsesMoveAndPonderMove() {
    let bestMove = expectBestMove("bestmove e2e4 ponder e7e5")

    #expect(bestMove.rawLine == "bestmove e2e4 ponder e7e5")
    #expect(bestMove.move == move("e2e4"))
    #expect(bestMove.ponder == move("e7e5"))
}

@Test func bestMoveParsesPromotionMove() {
    let bestMove = expectBestMove("bestmove e7e8q")

    #expect(bestMove.move == move("e7e8q"))
    #expect(bestMove.ponder == nil)
}

@Test func bestMoveParsesExtraWhitespaceAndMissingPonderSafely() {
    let bestMove = expectBestMove(" \t bestmove \t e1g1   ponder   ")

    #expect(bestMove.move == move("e1g1"))
    #expect(bestMove.ponder == nil)
}

@Test func bestMoveNoneAndNullMoveProduceNilMove() {
    let none = expectBestMove("bestmove (none)")
    let nullMove = expectBestMove("bestmove 0000")

    #expect(none.move == nil)
    #expect(none.ponder == nil)
    #expect(nullMove.move == nil)
    #expect(nullMove.ponder == nil)
}

@Test func bestMoveTreatsNoneAndNullPonderAsNoPonderMove() {
    let none = expectBestMove("bestmove e2e4 ponder (none)")
    let nullMove = expectBestMove("bestmove e2e4 ponder 0000")

    #expect(none.move == move("e2e4"))
    #expect(none.ponder == nil)
    #expect(nullMove.move == move("e2e4"))
    #expect(nullMove.ponder == nil)
}

@Test func malformedBestMoveLineStillParsesAsBestMoveOutput() {
    let bestMove = expectBestMove("bestmove not-a-move ponder also-bad")

    #expect(bestMove.move == nil)
    #expect(bestMove.ponder == nil)
}

@Test func infoParsesSearchMetadataScoreCurrentMoveAndPrincipalVariation() {
    let info = expectInfo(
        "info depth 16 seldepth 24 multipv 2 score cp 85 lowerbound "
            + "nodes 123456 nps 98765 time 4321 hashfull 123 currmove g1f3 "
            + "currmovenumber 12 tbhits 4 sbhits 5 cpuload 876 "
            + "pv e2e4 e7e5 g1f3"
    )

    #expect(info.depth == 16)
    #expect(info.selectiveDepth == 24)
    #expect(info.multipv == 2)
    #expect(info.score == .centipawns(85))
    #expect(info.scoreBound == .lowerbound)
    #expect(info.nodes == 123_456)
    #expect(info.nodesPerSecond == 98_765)
    #expect(info.timeMilliseconds == 4_321)
    #expect(info.hashfull == 123)
    #expect(info.currentMove == move("g1f3"))
    #expect(info.currentMoveNumber == 12)
    #expect(info.tablebaseHits == 4)
    #expect(info.shredderbaseHits == 5)
    #expect(info.cpuLoad == 876)
    #expect(info.principalVariation == [move("e2e4"), move("e7e5"), move("g1f3")])
}

@Test func infoParsesMateScoresAndUpperBounds() {
    let winning = expectInfo("info depth 10 score mate 3 upperbound pv h2h4")
    let losing = expectInfo("info depth 12 score mate -2 pv h7h5")

    #expect(winning.score == .mate(3))
    #expect(winning.scoreBound == .upperbound)
    #expect(winning.principalVariation == [move("h2h4")])
    #expect(losing.score == .mate(-2))
    #expect(losing.scoreBound == .exact)
    #expect(losing.principalVariation == [move("h7h5")])
}

@Test func infoParsesSignedCentipawnScores() {
    let positive = expectInfo("info score cp +23 pv e2e4")
    let negative = expectInfo("info score cp -140 pv d7d5")

    #expect(positive.score == .centipawns(23))
    #expect(negative.score == .centipawns(-140))
}

@Test func infoScoreBoundsDoNotHideFollowingFields() {
    let lowerBound = expectInfo("info score cp 25 lowerbound nodes 1000 pv e2e4")
    let upperBound = expectInfo("info score mate -4 upperbound time 77 pv g8f6")

    #expect(lowerBound.score == .centipawns(25))
    #expect(lowerBound.scoreBound == .lowerbound)
    #expect(lowerBound.nodes == 1_000)
    #expect(lowerBound.principalVariation == [move("e2e4")])
    #expect(upperBound.score == .mate(-4))
    #expect(upperBound.scoreBound == .upperbound)
    #expect(upperBound.timeMilliseconds == 77)
    #expect(upperBound.principalVariation == [move("g8f6")])
}

@Test func infoParsesRefutationAndCurrentLineFields() {
    let refutation = expectInfo("info refutation e2e4 e7e5 g1f3")
    let currentLineWithCPU = expectInfo("info currline 2 e2e4 c7c5 g1f3")
    let currentLineWithoutCPU = expectInfo("info currline e2e4 e7e5")

    #expect(refutation.refutation == [move("e2e4"), move("e7e5"), move("g1f3")])
    #expect(currentLineWithCPU.currentLine == UCICurrentLine(
        cpuNumber: 2,
        moves: [move("e2e4"), move("c7c5"), move("g1f3")]
    ))
    #expect(currentLineWithoutCPU.currentLine == UCICurrentLine(
        moves: [move("e2e4"), move("e7e5")]
    ))
}

@Test func infoParsesStringLinesAsFreeFormText() {
    let info = expectInfo("info string NNUE evaluation using nn-123.nnue")

    #expect(info.string == "NNUE evaluation using nn-123.nnue")
    #expect(info.score == nil)
    #expect(info.principalVariation.isEmpty)
}

@Test func infoStringKeepsRemainingTokensAsTextAfterEarlierFields() {
    let info = expectInfo("info depth 4 nodes 15 string searching move e2e4 score cp 10")

    #expect(info.depth == 4)
    #expect(info.nodes == 15)
    #expect(info.string == "searching move e2e4 score cp 10")
    #expect(info.score == nil)
}

@Test func infoIgnoresMalformedNumbersWithoutDroppingLaterFields() {
    let info = expectInfo(
        "info depth nope nodes 42 nps bad tbhits also-bad sbhits 8 "
            + "cpuload what time 15 score cp 12 pv e2e4"
    )

    #expect(info.depth == nil)
    #expect(info.nodes == 42)
    #expect(info.nodesPerSecond == nil)
    #expect(info.tablebaseHits == nil)
    #expect(info.shredderbaseHits == 8)
    #expect(info.cpuLoad == nil)
    #expect(info.timeMilliseconds == 15)
    #expect(info.score == .centipawns(12))
    #expect(info.principalVariation == [move("e2e4")])
}

@Test func infoIgnoresMalformedScoresWithoutDroppingLaterFields() {
    let info = expectInfo("info score cp nope depth 7 pv e2e4 bad-token e7e5")

    #expect(info.score == nil)
    #expect(info.scoreBound == .exact)
    #expect(info.depth == 7)
    #expect(info.principalVariation == [move("e2e4"), move("e7e5")])
}

@Test func infoIgnoresMalformedCurrentMoveWithoutDroppingLaterFields() {
    let info = expectInfo("info currmove bad-move currmovenumber no depth 5 score cp 31 pv d2d4 d7d5")

    #expect(info.currentMove == nil)
    #expect(info.currentMoveNumber == nil)
    #expect(info.depth == 5)
    #expect(info.score == .centipawns(31))
    #expect(info.principalVariation == [move("d2d4"), move("d7d5")])
}

@Test func infoLeavesUnknownScoreKindsNilWithoutDroppingLaterFields() {
    let info = expectInfo("info score wdl 10 20 30 depth 8 nodes 64 pv c2c4")

    #expect(info.score == nil)
    #expect(info.scoreBound == .exact)
    #expect(info.depth == 8)
    #expect(info.nodes == 64)
    #expect(info.principalVariation == [move("c2c4")])
}

@Test func unknownAndEmptyLinesRemainUnknown() {
    #expect(UCIParser().parse("custom engine output") == .unknown("custom engine output"))
    #expect(UCIParser().parse("id version 17") == .unknown("id version 17"))
    #expect(UCIParser().parse("   ") == .unknown("   "))
}

@Test func scoreNormalizationConvertsCentipawnsToWhiteRelativeValues() {
    let whiteScore = UCIScore.centipawns(85).whiteRelative(sideToMove: .white)
    let blackScore = UCIScore.centipawns(85).whiteRelative(sideToMove: .black)

    #expect(whiteScore == .centipawns(85))
    #expect(blackScore == .centipawns(-85))
}

@Test func scoreNormalizationConvertsMateScoresToMatingSide() {
    #expect(UCIScore.mate(3).whiteRelative(sideToMove: .white) == .mate(moves: 3, side: .white))
    #expect(UCIScore.mate(-2).whiteRelative(sideToMove: .white) == .mate(moves: 2, side: .black))
    #expect(UCIScore.mate(4).whiteRelative(sideToMove: .black) == .mate(moves: 4, side: .black))
    #expect(UCIScore.mate(-1).whiteRelative(sideToMove: .black) == .mate(moves: 1, side: .white))
}

@Test func infoLineConvenienceReturnsWhiteRelativeScore() {
    let blackToMoveInfo = expectInfo("info score cp 50 pv e7e5")

    #expect(blackToMoveInfo.whiteRelativeScore(sideToMove: .black) == .centipawns(-50))
}

@Test func publicAPIsAreConstructible() {
    let bestMove = UCIBestMove(rawLine: "bestmove e2e4", move: move("e2e4"))
    let info = UCIInfoLine(
        rawLine: "info score cp 1",
        depth: 1,
        score: .centipawns(1),
        currentMoveNumber: 2,
        principalVariation: [move("e2e4")],
        refutation: [move("d2d4")],
        currentLine: UCICurrentLine(cpuNumber: 1, moves: [move("g1f3")]),
        tablebaseHits: 3,
        shredderbaseHits: 4,
        cpuLoad: 500
    )
    let option = UCIOption(
        rawLine: "option name Skill Level type spin default 20 min 0 max 20",
        name: "Skill Level",
        type: .spin,
        defaultValue: "20",
        min: 0,
        max: 20
    )

    #expect(bestMove.move == move("e2e4"))
    #expect(info.depth == 1)
    #expect(info.score == .centipawns(1))
    #expect(info.scoreBound == .exact)
    #expect(info.currentMoveNumber == 2)
    #expect(info.principalVariation == [move("e2e4")])
    #expect(info.refutation == [move("d2d4")])
    #expect(info.currentLine == UCICurrentLine(cpuNumber: 1, moves: [move("g1f3")]))
    #expect(info.tablebaseHits == 3)
    #expect(info.shredderbaseHits == 4)
    #expect(info.cpuLoad == 500)
    #expect(option.name == "Skill Level")
    #expect(option.type == .spin)
    #expect(option.defaultValue == "20")
}

private func expectBestMove(
    _ line: String,
    sourceLocation: SourceLocation = #_sourceLocation
) -> UCIBestMove {
    guard case .bestMove(let bestMove) = UCIParser().parse(line) else {
        Issue.record("Expected bestmove line for \(line)", sourceLocation: sourceLocation)
        return UCIBestMove(rawLine: line, move: nil)
    }

    return bestMove
}

private func expectInfo(
    _ line: String,
    sourceLocation: SourceLocation = #_sourceLocation
) -> UCIInfoLine {
    guard case .info(let info) = UCIParser().parse(line) else {
        Issue.record("Expected info line for \(line)", sourceLocation: sourceLocation)
        return UCIInfoLine(rawLine: line)
    }

    return info
}

private func expectOption(
    _ line: String,
    sourceLocation: SourceLocation = #_sourceLocation
) -> UCIOption {
    guard case .option(let option) = UCIParser().parse(line) else {
        Issue.record("Expected option line for \(line)", sourceLocation: sourceLocation)
        return UCIOption(rawLine: line, name: "", type: .unknown(""))
    }

    return option
}

private func move(_ value: String) -> Move {
    try! Move(string: value)
}
