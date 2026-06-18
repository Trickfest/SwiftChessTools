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

@Test func basicCommandsRenderUCIText() {
    #expect(UCICommand.uci.string == "uci")
    #expect(UCICommand.isReady.string == "isready")
    #expect(UCICommand.newGame.string == "ucinewgame")
    #expect(UCICommand.stop.string == "stop")
    #expect(UCICommand.ponderHit.string == "ponderhit")
    #expect(UCICommand.quit.string == "quit")
    #expect(UCICommand.debug(true).string == "debug on")
    #expect(UCICommand.debug(false).string == "debug off")
    #expect(UCICommand.registerLater.string == "register later")
    #expect(UCICommand.register(name: "Jane Doe", code: "ABC 123").string == "register name Jane Doe code ABC 123")
}

@Test func setOptionCommandsRenderNamesAndValues() {
    #expect(UCICommand.setOption(name: "Clear Hash").string == "setoption name Clear Hash")
    #expect(UCICommand.setOption(name: "Hash", value: 128).string == "setoption name Hash value 128")
    #expect(UCICommand.setOption(name: "UCI_AnalyseMode", value: true).string == "setoption name UCI_AnalyseMode value true")
    #expect(UCICommand.setOption(name: "Ponder", value: false).string == "setoption name Ponder value false")
    #expect(
        UCICommand.setOption(name: "SyzygyPath", value: "/tb/one:/tb/two").string
            == "setoption name SyzygyPath value /tb/one:/tb/two"
    )
}

@Test func positionCommandsRenderStartposFenAndMoves() throws {
    let moves = try ["e2e4", "e7e5", "g1f3"].map(Move.init(string:))
    let promotion = try Move(string: "a7a8Q")
    let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    #expect(UCICommand.position(.startpos).string == "position startpos")
    #expect(
        UCICommand.position(.startpos, moves: moves).string
            == "position startpos moves e2e4 e7e5 g1f3"
    )
    #expect(
        UCICommand.position(.fen(fen)).string
            == "position fen \(fen)"
    )
    #expect(
        UCICommand.position(.fen(fen), moves: [promotion]).string
            == "position fen \(fen) moves a7a8q"
    )
}

@Test func goCommandsRenderCommonSearchLimits() throws {
    #expect(UCICommand.go(UCIGoOptions()).string == "go")
    #expect(UCICommand.go(.depth(12)).string == "go depth 12")
    #expect(UCICommand.go(.moveTime(milliseconds: 500)).string == "go movetime 500")
    #expect(UCICommand.go(.infiniteSearch()).string == "go infinite")

    let moves = try ["e2e4", "d2d4"].map(Move.init(string:))
    #expect(
        UCICommand.go(.depth(8, searchMoves: moves)).string
            == "go searchmoves e2e4 d2d4 depth 8"
    )
}

@Test func goCommandsRenderFullSearchOptionsInStableOrder() throws {
    let moves = try ["e2e4", "g1f3"].map(Move.init(string:))
    let options = UCIGoOptions(
        searchMoves: moves,
        ponder: true,
        whiteTimeMilliseconds: 300_000,
        blackTimeMilliseconds: 295_000,
        whiteIncrementMilliseconds: 2_000,
        blackIncrementMilliseconds: 2_000,
        movesToGo: 30,
        depth: 18,
        nodes: 1_000_000,
        mate: 4,
        moveTimeMilliseconds: 750,
        infinite: true
    )

    #expect(
        UCICommand.go(options).string
            == "go searchmoves e2e4 g1f3 ponder wtime 300000 btime 295000 "
            + "winc 2000 binc 2000 movestogo 30 depth 18 nodes 1000000 "
            + "mate 4 movetime 750 infinite"
    )
}

@Test func commandRawValueDescriptionAndEquatabilityArePubliclyUsable() {
    let command = UCICommand(rawValue: "register later")

    #expect(command.rawValue == "register later")
    #expect(command.string == "register later")
    #expect(command.description == "register later")
    #expect(command == UCICommand(rawValue: "register later"))
}
