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

@testable import ChessCore

@Test func pgnParsesTaggedScholarsMate() throws {
    let pgn = """
        [Event "Synthetic Scholar's Mate"]
        [Site "?"]
        [Date "2026.06.12"]
        [Round "1"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]

        1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.tagValue(for: "Event") == "Synthetic Scholar's Mate")
    #expect(game.result == .whiteWins)
    #expect(game.moveRecords.map(\.san) == ["e4", "e5", "Bc4", "Nc6", "Qh5", "Nf6", "Qxf7#"])
    #expect(game.mainlineMoves.map(\.description) == [
        "e2e4", "e7e5", "f1c4", "b8c6", "d1h5", "g8f6", "h5f7",
    ])
    #expect(
        FENSerializer().fen(from: game.finalPosition)
            == "r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4"
    )
}

@Test func pgnParsesMultipleGames() throws {
    let database = """
        [Event "Game One"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "0-1"]

        1. f4 e5 2. g4 Qh4# 0-1

        [Event "Game Two"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4 c5 *
        """

    let games = try PGNSerializer().games(from: database)

    #expect(games.count == 2)
    #expect(games[0].result == .blackWins)
    #expect(games[0].moveRecords.last?.san == "Qh4#")
    #expect(games[1].result == .unfinished)
    #expect(games[1].mainlineMoves.map(\.description) == ["e2e4", "c7c5"])
}

@Test func pgnPreservesCommentsClockEvaluationsAndNAGs() throws {
    let pgn = """
        [Event "Synthetic Comments"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4! { [%eval 0.17] [%clk 0:05:00] } 1... e5 $2
        2. Nf3!? Nc6?! *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords[0].san == "e4")
    #expect(game.moveRecords[0].nags.map(\.rawValue) == [1])
    #expect(game.moveRecords[0].comments == ["[%eval 0.17] [%clk 0:05:00]"])
    #expect(game.moveRecords[1].nags.map(\.rawValue) == [2])
    #expect(game.moveRecords[2].nags.map(\.rawValue) == [5])
    #expect(game.moveRecords[3].nags.map(\.rawValue) == [6])
}

@Test func pgnParsesDialectCommentsEscapeLinesRepeatedTagsAndResultAdjacency() throws {
    let pgn = #"""
        % ignored escape line before tags
        [Event "Synthetic Dialect Stress"]
        [Site "https://lichess.org/synthetic"]
        [Date "2026.06.14"]
        [Round "?"]
        [White "Escaped \"White\""]
        [Black "Backslash \\ Black"]
        [Result "*"]
        [Annotator "Primary"]
        [Annotator ""]

        { loose pre-game comment is ignored }
        % ignored escape line before movetext
        1. e4 {} ; semicolon comments attach to the previous move
        % ignored escape line between moves
        1... e5 {[%emt 0:00:01]} 2. Nf3 {   } Nc6 { [%clk 0:03:00] [%eval 0.24] [%emt 0:00:02] } { trailing move comment } * { post-result comment is ignored }
        """#

    let serializer = PGNSerializer()
    let game = try serializer.game(from: pgn)
    let exported = try serializer.pgn(from: game, lineWidth: 120)

    #expect(game.tagValue(for: "White") == #"Escaped "White""#)
    #expect(game.tagValue(for: "Black") == #"Backslash \ Black"#)
    #expect(game.tagPairs.filter { $0.name == "Annotator" }.map(\.value) == ["Primary", ""])
    #expect(game.moveRecords.map(\.san) == ["e4", "e5", "Nf3", "Nc6"])
    #expect(game.moveRecords[0].comments == ["", "semicolon comments attach to the previous move"])
    #expect(game.moveRecords[1].comments == ["[%emt 0:00:01]"])
    #expect(game.moveRecords[2].comments == [""])
    #expect(game.moveRecords[3].comments == [
        "[%clk 0:03:00] [%eval 0.24] [%emt 0:00:02]",
        "trailing move comment",
    ])
    #expect(exported.contains(#"[White "Escaped \"White\""]"#))
    #expect(exported.contains(#"[Black "Backslash \\ Black"]"#))
    #expect(exported.contains("[Annotator \"Primary\"]"))
    #expect(exported.contains("[Annotator \"\"]"))
}

@Test func pgnParsesLichessStyleElapsedTimeMiniCorpus() throws {
    let database = """
        [Event "Rated blitz game"]
        [Site "https://lichess.org/synthetic-emt-1"]
        [Date "2026.06.14"]
        [Round "-"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [UTCDate "2026.06.14"]
        [UTCTime "12:00:00"]
        [WhiteElo "1500"]
        [BlackElo "1500"]
        [TimeControl "180+2"]
        [Termination "Unterminated"]

        1. e4 { [%clk 0:03:00] [%eval 0.20] [%emt 0:00:01] } c5 2. Nf3 d6 *

        [Event "Rated classical game"]
        [Site "https://lichess.org/synthetic-emt-2"]
        [Date "2026.06.14"]
        [Round "-"]
        [White "White"]
        [Black "Black"]
        [Result "1/2-1/2"]
        [TimeControl "1800+0"]
        [Termination "Normal"]

        1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 1/2-1/2

        [Event "Rated bullet game"]
        [Site "https://lichess.org/synthetic-emt-3"]
        [Date "2026.06.14"]
        [Round "-"]
        [White "White"]
        [Black "Black"]
        [Result "0-1"]
        [TimeControl "60+0"]
        [Termination "Normal"]

        1. f3 { [%clk 0:01:00] } e5 { [%clk 0:01:00] [%eval -0.20] } 2. g4?? Qh4# 0-1
        """

    let games = try PGNSerializer().games(from: database)

    #expect(games.count == 3)
    #expect(games.map { $0.tagValue(for: "Site") } == [
        "https://lichess.org/synthetic-emt-1",
        "https://lichess.org/synthetic-emt-2",
        "https://lichess.org/synthetic-emt-3",
    ])
    #expect(games.map(\.result) == [.unfinished, .draw, .blackWins])
    #expect(games.map { $0.moveRecords.count } == [4, 6, 4])
    #expect(games[0].moveRecords[0].comments == ["[%clk 0:03:00] [%eval 0.20] [%emt 0:00:01]"])
    #expect(games[2].moveRecords[2].nags.map(\.rawValue) == [4])
    #expect(games[2].moveRecords[3].san == "Qh4#")
}

@Test func pgnParsesExpandedDialectCorpus() throws {
    let database = #"""
        % ignored escape line before the first game
        [Event "Dialect \"Tag\" Corpus"]
        [Site "https://lichess.org/synthetic-dialect-1"]
        [Date "2026.06.14"]
        [Round "-"]
        [White "Quote \" White"]
        [Black "Slash \\ Black"]
        [Result "*"]
        [Annotator "Primary"]
        [Annotator "Secondary"]
        [Opening "Queen's Pawn \\ Line"]

        ; loose line comment before movetext is ignored
        1.d4 {[%clk 0:10:00.5][%eval 0.32]} Nf6 { [%eval #4] }
        % ignored escape line between moves
        2.c4 {[%emt 0:00:01.25]} e6 { [%cal Ge7e5,Rg8f6] [%csl Gd4] } *

        [Event "Result Comment Boundary"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]

        1. e4 { comment before external result } 1-0 { comment after result is ignored }

        [Event "Empty Comments And Semicolons"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        { loose brace comment is ignored }
        ; loose semicolon comment is ignored
        1. e4 {} ; line comment attaches to e4
        1... c5 {   } 2. Nf3 $0 $01 *

        [Event "FEN Backed Dialect"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1"]

        1... O-O-O { [%clk 0:00:59.99] [%emt 0:00:00.01] } *
        """#

    let games = try PGNSerializer().games(from: database)

    #expect(games.count == 4)

    #expect(games[0].tagValue(for: "Event") == #"Dialect "Tag" Corpus"#)
    #expect(games[0].tagValue(for: "White") == #"Quote " White"#)
    #expect(games[0].tagValue(for: "Black") == #"Slash \ Black"#)
    #expect(games[0].tagPairs.filter { $0.name == "Annotator" }.map(\.value) == ["Primary", "Secondary"])
    #expect(games[0].moveRecords.map(\.san) == ["d4", "Nf6", "c4", "e6"])
    #expect(games[0].moveRecords[0].comments == ["[%clk 0:10:00.5][%eval 0.32]"])
    #expect(games[0].moveRecords[1].comments == ["[%eval #4]"])
    #expect(games[0].moveRecords[2].comments == ["[%emt 0:00:01.25]"])
    #expect(games[0].moveRecords[3].comments == ["[%cal Ge7e5,Rg8f6] [%csl Gd4]"])

    #expect(games[1].result == .whiteWins)
    #expect(games[1].moveRecords.map(\.san) == ["e4"])
    #expect(games[1].moveRecords[0].comments == ["comment before external result"])

    #expect(games[2].moveRecords.map(\.san) == ["e4", "c5", "Nf3"])
    #expect(games[2].moveRecords[0].comments == ["", "line comment attaches to e4"])
    #expect(games[2].moveRecords[1].comments == [""])
    #expect(games[2].moveRecords[2].nags.map(\.rawValue) == [0, 1])

    #expect(games[3].moveRecords.map(\.san) == ["O-O-O"])
    #expect(games[3].mainlineMoves.map(\.description) == ["e8c8"])
    #expect(games[3].moveRecords[0].comments == ["[%clk 0:00:59.99] [%emt 0:00:00.01]"])
}

@Test func pgnParsesEscapedTagValuesAndExportsThem() throws {
    let pgn = #"""
        [Event "Quote \" and slash \\"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4 *
        """#

    let serializer = PGNSerializer()
    let game = try serializer.game(from: pgn)
    let exported = try serializer.pgn(from: game)

    #expect(game.tagValue(for: "Event") == #"Quote " and slash \"#)
    #expect(exported.contains(#"[Event "Quote \" and slash \\"]"#))
}

@Test func pgnParsesUTF8BOMMissingRosterAndOddTagNames() throws {
    let pgn = "\u{FEFF}" + """
        [Event "BOM And Sparse Tags"]
        [White-Team "A"]
        [Black_Title "GM"]
        [Result "*"]

        *
        """

    let serializer = PGNSerializer()
    let game = try serializer.game(from: pgn)
    let exported = try serializer.pgn(from: game)

    #expect(game.moveRecords.isEmpty)
    #expect(game.tagValue(for: "Event") == "BOM And Sparse Tags")
    #expect(game.tagValue(for: "White-Team") == "A")
    #expect(game.tagValue(for: "Black_Title") == "GM")
    #expect(exported.contains("[Site \"?\"]"))
    #expect(exported.contains("[White \"?\"]"))
    #expect(exported.contains("[Black \"?\"]"))
    #expect(exported.contains("[White-Team \"A\"]"))
    #expect(exported.contains("[Black_Title \"GM\"]"))
}

@Test func pgnParsesCastlingForBothSides() throws {
    let pgn = """
        [Event "Synthetic Castling"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. O-O Be7 5. Re1 O-O *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords[6].san == "O-O")
    #expect(game.moveRecords[6].move.description == "e1g1")
    #expect(game.moveRecords[9].san == "O-O")
    #expect(game.moveRecords[9].move.description == "e8g8")
}

@Test func pgnParsesSparseRosterEmptyGameAndLeadingComments() throws {
    let pgn = """
        [Event "Sparse Empty"]
        [Result "*"]

        { leading comment before movetext is ignored }
        *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.tagValue(for: "Event") == "Sparse Empty")
    #expect(game.result == .unfinished)
    #expect(game.moveRecords.isEmpty)
    #expect(game.mainlineMoves.isEmpty)
    #expect(game.finalPosition == game.initialPosition)
}

@Test func pgnParsesFenBackedPromotion() throws {
    let pgn = """
        [Event "Synthetic Promotion"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "8/P4pk1/6p1/6Pp/3b3P/8/8/4K3 w - - 0 1"]

        1. a8=Q *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords.map(\.san) == ["a8=Q"])
    #expect(game.mainlineMoves.map(\.description) == ["a7a8q"])
}

@Test func pgnParsesFenBackedBlackUnderpromotion() throws {
    let pgn = """
        [Event "Synthetic Black Underpromotion"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "4k3/8/8/7p/6p1/2N3P1/p4PKP/8 b - - 0 1"]

        1... a1=N *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords.map(\.san) == ["a1=N"])
    #expect(game.moveRecords[0].color == .black)
    #expect(game.mainlineMoves.map(\.description) == ["a2a1n"])
}

@Test func pgnParsesEnPassantCapture() throws {
    let pgn = """
        [Event "Synthetic En Passant"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "rnbqkbnr/pp2pppp/8/2ppP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3"]

        3. exd6 *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords[0].san == "exd6")
    #expect(game.mainlineMoves.map(\.description) == ["e5d6"])
    #expect(FENSerializer().fen(from: game.finalPosition).contains("3P4"))
}

@Test func pgnParsesDisambiguatedSAN() throws {
    let pgn = """
        [Event "Synthetic Disambiguation"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "1n2k1n1/8/8/8/8/1N3N2/8/4K3 w - - 0 1"]

        1. Nbd4 *
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords[0].san == "Nbd4")
    #expect(game.mainlineMoves.map(\.description) == ["b3d4"])
}

@Test func pgnExportsAndReparsesRoundTrip() throws {
    let serializer = PGNSerializer()
    let original = try serializer.game(from: """
        [Event "Round Trip"]
        [Site "Local"]
        [Date "2026.06.12"]
        [Round "1"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]
        [Annotator "SwiftChessTools"]

        1. e4 { comment } e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0
        """)

    let exported = try serializer.pgn(from: original, lineWidth: 32)
    let reparsed = try serializer.game(from: exported)

    #expect(reparsed.result == original.result)
    #expect(reparsed.mainlineMoves == original.mainlineMoves)
    #expect(reparsed.finalPosition == original.finalPosition)
    #expect(exported.contains("[Annotator \"SwiftChessTools\"]"))
}

@Test func pgnBuildsFromConcreteMovesAndExportsSevenTagRoster() throws {
    let serializer = PGNSerializer()
    let moves = try ["e2e4", "e7e5", "g1f3", "b8c6"].map { try Move(string: $0) }
    let exported = try serializer.pgn(
        moves: moves,
        tags: [
            PGNTagPair(name: "Event", value: "Generated"),
            PGNTagPair(name: "White", value: "Alice"),
            PGNTagPair(name: "Black", value: "Bob"),
        ],
        result: .unfinished,
        lineWidth: 80
    )

    #expect(exported.hasPrefix("""
        [Event "Generated"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "Alice"]
        [Black "Bob"]
        [Result "*"]
        """))
    #expect(exported.contains("1. e4 e5 2. Nf3 Nc6 *"))
    #expect(try serializer.game(from: exported).mainlineMoves == moves)
}

@Test func pgnExportsFenBackedGameWithSetupTags() throws {
    let serializer = PGNSerializer()
    let initialPosition = try FENSerializer().position(
        from: "8/P4pk1/6p1/6Pp/3b3P/8/8/4K3 w - - 0 1"
    )
    let exported = try serializer.pgn(
        initialPosition: initialPosition,
        moves: [try Move(string: "a7a8q")],
        result: .unfinished
    )

    #expect(exported.contains("[SetUp \"1\"]"))
    #expect(exported.contains("[FEN \"8/P4pk1/6p1/6Pp/3b3P/8/8/4K3 w - - 0 1\"]"))
    #expect(try serializer.game(from: exported).mainlineMoves.map(\.description) == ["a7a8q"])
}

@Test func pgnRejectsResultTagMovetextMismatch() throws {
    expectPGNParsingError("""
        [Event "Mismatch"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]

        1. e4 e5 0-1
        """) { error in
        if case .resultMismatch(tag: .whiteWins, movetext: .blackWins, _) = error {
            return true
        }
        return false
    }
}

@Test func pgnRejectsResultsThatConflictWithTerminalCheckmateStatus() throws {
    expectPGNParsingError("""
        [Event "Unfinished Checkmate"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. f3 e5 2. g4 Qh4# *
        """) { error in
        if case let .resultConflictsWithFinalStatus(result, status, context) = error {
            return result == .unfinished
                && status == .checkmate(winner: .black)
                && context.gameIndex == 0
        }
        return false
    }

    expectPGNParsingError("""
        [Event "Wrong Winner"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]

        1. f3 e5 2. g4 Qh4# 1-0
        """) { error in
        if case let .resultConflictsWithFinalStatus(result, status, context) = error {
            return result == .whiteWins
                && status == .checkmate(winner: .black)
                && context.gameIndex == 0
        }
        return false
    }
}

@Test func pgnValidatesTerminalDrawResultsButAllowsOngoingExternalResults() throws {
    expectPGNParsingError("""
        [Event "Wrong Stalemate Result"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "0-1"]
        [SetUp "1"]
        [FEN "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"]

        0-1
        """) { error in
        if case let .resultConflictsWithFinalStatus(result, status, context) = error {
            return result == .blackWins
                && status == .draw(.stalemate)
                && context.gameIndex == 0
        }
        return false
    }

    let terminalDraw = try PGNSerializer().game(from: """
        [Event "Correct Stalemate Result"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1/2-1/2"]
        [SetUp "1"]
        [FEN "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"]

        1/2-1/2
        """)
    #expect(terminalDraw.result == .draw)
    #expect(Game(position: terminalDraw.finalPosition).status == .draw(.stalemate))

    expectPGNParsingError("""
        [Event "Wrong Dead Position Result"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]
        [SetUp "1"]
        [FEN "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"]

        1-0
        """) { error in
        if case let .resultConflictsWithFinalStatus(result, status, context) = error {
            return result == .whiteWins
                && status == .draw(.deadPosition)
                && context.gameIndex == 0
        }
        return false
    }

    let deadPositionDraw = try PGNSerializer().game(from: """
        [Event "Correct Dead Position Result"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1/2-1/2"]
        [SetUp "1"]
        [FEN "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"]

        1/2-1/2
        """)
    #expect(deadPositionDraw.result == .draw)
    #expect(Game(position: deadPositionDraw.finalPosition).status == .draw(.deadPosition))

    let resignation = try PGNSerializer().game(from: """
        [Event "External Result"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "1-0"]

        1. e4 1-0
        """)
    #expect(resignation.result == .whiteWins)
    #expect(Game(position: resignation.finalPosition).status == .ongoing(drawClaims: Set<GameDrawClaim>()))

    let claimableDraw = try PGNSerializer().game(from: """
        [Event "Claimable Draw Not Claimed"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "4k3/8/8/8/8/8/Q7/4K3 w - - 100 1"]

        *
        """)
    #expect(claimableDraw.result == .unfinished)
    #expect(
        Game(position: claimableDraw.finalPosition).status
            == .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule]))
    )
}

@Test("PGN accepts result markers required by terminal final status", arguments: terminalStatusAcceptedResultCases)
private func pgnAcceptsRequiredResultsForTerminalFinalStatuses(testCase: PGNStatusResultCase) throws {
    let game = try PGNSerializer().game(from: testCase.pgn)

    #expect(game.result == testCase.result, "\(testCase.name)")
    #expect(game.finalStatus == testCase.expectedStatus, "\(testCase.name)")
    #expect(game.requiredResultForFinalStatus == testCase.result, "\(testCase.name)")
    #expect(game.resultMatchesFinalStatus, "\(testCase.name)")
}

@Test("PGN rejects result markers that conflict with terminal final status", arguments: terminalStatusRejectedResultCases)
private func pgnRejectsResultsThatConflictWithTerminalFinalStatuses(testCase: PGNStatusResultCase) {
    expectPGNParsingError(testCase.pgn) { error in
        if case let .resultConflictsWithFinalStatus(result, status, context) = error {
            return result == testCase.result
                && status == testCase.expectedStatus
                && context.gameIndex == 0
        }
        return false
    }
}

@Test("PGN accepts external result markers for ongoing final status", arguments: ongoingStatusAcceptedResultCases)
private func pgnAcceptsExternalResultsForOngoingFinalStatuses(testCase: PGNStatusResultCase) throws {
    let game = try PGNSerializer().game(from: testCase.pgn)

    #expect(game.result == testCase.result, "\(testCase.name)")
    #expect(game.finalStatus == testCase.expectedStatus, "\(testCase.name)")
    #expect(game.requiredResultForFinalStatus == nil, "\(testCase.name)")
    #expect(game.resultMatchesFinalStatus, "\(testCase.name)")
}

@Test func pgnRejectsInvalidSANWithContext() throws {
    expectPGNParsingError("""
        [Event "Invalid SAN"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e5 *
        """) { error in
        if case let .sanParsingFailed("e5", .noMatchingLegalMove("e5"), context) = error {
            return context.ply == 1 && context.moveNumber == 1
        }
        return false
    }
}

@Test func pgnRejectsInvalidTags() throws {
    expectPGNParsingError("""
        [1Bad "value"]

        *
        """) { error in
        if case .invalidTag = error {
            return true
        }
        return false
    }
}

@Test func pgnRejectsMissingFenForSetup() throws {
    expectPGNParsingError("""
        [Event "Missing FEN"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]

        *
        """) { error in
        if case .missingFEN = error {
            return true
        }
        return false
    }
}

@Test func pgnRejectsInvalidFenTag() throws {
    expectPGNParsingError("""
        [Event "Invalid FEN"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]
        [SetUp "1"]
        [FEN "8/8/8/8/8/8/8 w - - 0 1"]

        *
        """) { error in
        if case .fenParsingFailed(_, .invalidPiecePlacement, _) = error {
            return true
        }
        return false
    }
}

@Test func pgnRejectsRecursiveVariationsForFirstPass() throws {
    expectPGNParsingError("""
        [Event "Variation"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4 (1. d4) e5 *
        """) { error in
        if case .unsupportedRecursiveVariation = error {
            return true
        }
        return false
    }
}

@Test func pgnRejectsUnterminatedCommentsAndStrings() throws {
    expectPGNParsingError("""
        [Event "Open Comment"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        1. e4 { never ends
        """) { error in
        if case .unterminatedComment = error {
            return true
        }
        return false
    }

    expectPGNParsingError("""
        [Event "Open String]

        *
        """) { error in
        if case .unterminatedString = error {
            return true
        }
        return false
    }
}

@Test func pgnRejectsEmptyInputAndSingleGameMismatches() throws {
    expectPGNParsingError("") { error in
        error == .emptyInput
    }

    expectPGNParsingError("""
        [Event "One"]
        [Result "*"]
        *

        [Event "Two"]
        [Result "*"]
        *
        """, parseSingleGame: true) { error in
        error == .expectedSingleGame(actual: 2)
    }
}

@Test func pgnRejectsInvalidResultTagAndNAGs() throws {
    expectPGNParsingError("""
        [Event "Invalid Result Tag"]
        [Result "1/2"]

        *
        """) { error in
        if case let .invalidResultMarker("1/2", context) = error {
            return context.token == "1/2"
        }
        return false
    }

    expectPGNParsingError("""
        [Event "Invalid NAG"]
        [Result "*"]

        1. e4 $256 *
        """) { error in
        if case .invalidNAG("$256", _) = error {
            return true
        }
        return false
    }

    expectPGNParsingError("""
        [Event "NAG Before Move"]
        [Result "*"]

        $1 *
        """) { error in
        if case let .unexpectedToken("$1", context) = error {
            return context.token == "$1"
        }
        return false
    }
}

@Test func pgnRejectsIllegalMovesWhenExportingConcreteMoveLists() throws {
    do {
        _ = try PGNSerializer().pgn(moves: [try Move(string: "e2e5")])
        Issue.record("Expected illegal move export to fail")
    } catch let error as PGNSerializationError {
        if case let .illegalMove(move, context) = error {
            #expect(move.description == "e2e5")
            #expect(context.ply == 1)
        } else {
            Issue.record("Expected illegalMove, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }
}

@Test func pgnRejectsExportedResultsThatConflictWithFinalStatus() throws {
    let serializer = PGNSerializer()
    let foolsMate = try ["f2f3", "e7e5", "g2g4", "d8h4"].map { try Move(string: $0) }

    do {
        _ = try serializer.pgn(moves: foolsMate, result: .whiteWins)
        Issue.record("Expected checkmate result conflict to fail")
    } catch let error as PGNSerializationError {
        if case let .resultConflictsWithFinalStatus(result, status, _) = error {
            #expect(result == .whiteWins)
            #expect(status == .checkmate(winner: .black))
        } else {
            Issue.record("Expected resultConflictsWithFinalStatus, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }

    let checkmateExport = try serializer.pgn(moves: foolsMate, result: .blackWins)
    #expect(checkmateExport.contains("Qh4# 0-1"))

    let stalemate = try FENSerializer().position(
        from: "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"
    )
    do {
        _ = try serializer.pgn(initialPosition: stalemate, moves: [], result: .blackWins)
        Issue.record("Expected stalemate result conflict to fail")
    } catch let error as PGNSerializationError {
        if case let .resultConflictsWithFinalStatus(result, status, _) = error {
            #expect(result == .blackWins)
            #expect(status == .draw(.stalemate))
        } else {
            Issue.record("Expected resultConflictsWithFinalStatus, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }

    let stalemateExport = try serializer.pgn(initialPosition: stalemate, moves: [], result: .draw)
    #expect(stalemateExport.contains("1/2-1/2"))

    let deadPosition = try FENSerializer().position(
        from: "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"
    )
    do {
        _ = try serializer.pgn(initialPosition: deadPosition, moves: [], result: .whiteWins)
        Issue.record("Expected dead-position result conflict to fail")
    } catch let error as PGNSerializationError {
        if case let .resultConflictsWithFinalStatus(result, status, _) = error {
            #expect(result == .whiteWins)
            #expect(status == .draw(.deadPosition))
        } else {
            Issue.record("Expected resultConflictsWithFinalStatus, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }

    let deadPositionExport = try serializer.pgn(initialPosition: deadPosition, moves: [], result: .draw)
    #expect(deadPositionExport.contains("1/2-1/2"))
}

@Test("PGN export accepts result markers required by terminal final status", arguments: terminalStatusAcceptedResultCases)
private func pgnExportAcceptsRequiredResultsForTerminalFinalStatuses(testCase: PGNStatusResultCase) throws {
    let exported = try exportedPGN(for: testCase)
    let reparsed = try PGNSerializer().game(from: exported)

    #expect(reparsed.result == testCase.result, "\(testCase.name)")
    #expect(reparsed.finalStatus == testCase.expectedStatus, "\(testCase.name)")
    #expect(reparsed.resultMatchesFinalStatus, "\(testCase.name)")
}

@Test("PGN export rejects result markers that conflict with terminal final status", arguments: terminalStatusRejectedResultCases)
private func pgnExportRejectsResultsThatConflictWithTerminalFinalStatuses(testCase: PGNStatusResultCase) throws {
    do {
        _ = try exportedPGN(for: testCase)
        Issue.record("Expected PGN export to reject result conflict: \(testCase.name)")
    } catch let error as PGNSerializationError {
        if case let .resultConflictsWithFinalStatus(result, status, _) = error {
            #expect(result == testCase.result, "\(testCase.name)")
            #expect(status == testCase.expectedStatus, "\(testCase.name)")
        } else {
            Issue.record("Expected resultConflictsWithFinalStatus, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }
}

@Test("PGN export accepts external result markers for ongoing final status", arguments: ongoingStatusAcceptedResultCases)
private func pgnExportAcceptsExternalResultsForOngoingFinalStatuses(testCase: PGNStatusResultCase) throws {
    let exported = try exportedPGN(for: testCase)
    let reparsed = try PGNSerializer().game(from: exported)

    #expect(reparsed.result == testCase.result, "\(testCase.name)")
    #expect(reparsed.finalStatus == testCase.expectedStatus, "\(testCase.name)")
    #expect(reparsed.resultMatchesFinalStatus, "\(testCase.name)")
}

@Test func pgnGameExportValidatesManuallyConstructedGameModels() throws {
    let serializer = PGNSerializer()
    let checkmate = try serializer.game(from: statusTestPGN(
        name: "Manual Model Checkmate",
        source: .movetext("1. f3 e5 2. g4 Qh4#"),
        result: .blackWins
    ))

    let wrongResult = PGNGame(
        tagPairs: checkmate.tagPairs,
        initialPosition: checkmate.initialPosition,
        moveRecords: checkmate.moveRecords,
        result: .whiteWins,
        finalPosition: checkmate.finalPosition,
        finalStatus: checkmate.finalStatus
    )

    do {
        _ = try serializer.pgn(from: wrongResult)
        Issue.record("Expected manually constructed wrong result to fail")
    } catch let error as PGNSerializationError {
        if case let .resultConflictsWithFinalStatus(result, status, _) = error {
            #expect(result == .whiteWins)
            #expect(status == .checkmate(winner: .black))
        } else {
            Issue.record("Expected resultConflictsWithFinalStatus, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }

    let wrongFinalStatus = PGNGame(
        tagPairs: checkmate.tagPairs,
        initialPosition: checkmate.initialPosition,
        moveRecords: checkmate.moveRecords,
        result: checkmate.result,
        finalPosition: checkmate.finalPosition,
        finalStatus: .ongoing(drawClaims: Set<GameDrawClaim>())
    )

    do {
        _ = try serializer.pgn(from: wrongFinalStatus)
        Issue.record("Expected manually constructed wrong finalStatus to fail")
    } catch let error as PGNSerializationError {
        if case let .finalStatusMismatch(expected, actual, _) = error {
            #expect(expected == .checkmate(winner: .black))
            #expect(actual == .ongoing(drawClaims: Set<GameDrawClaim>()))
        } else {
            Issue.record("Expected finalStatusMismatch, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }

    var wrongSANRecords = checkmate.moveRecords
    wrongSANRecords[0] = PGNMoveRecord(
        ply: wrongSANRecords[0].ply,
        moveNumber: wrongSANRecords[0].moveNumber,
        color: wrongSANRecords[0].color,
        san: "e4",
        sourceSAN: wrongSANRecords[0].sourceSAN,
        move: wrongSANRecords[0].move,
        comments: wrongSANRecords[0].comments,
        nags: wrongSANRecords[0].nags
    )
    let wrongSAN = PGNGame(
        tagPairs: checkmate.tagPairs,
        initialPosition: checkmate.initialPosition,
        moveRecords: wrongSANRecords,
        result: checkmate.result,
        finalPosition: checkmate.finalPosition,
        finalStatus: checkmate.finalStatus
    )

    do {
        _ = try serializer.pgn(from: wrongSAN)
        Issue.record("Expected manually constructed wrong SAN to fail")
    } catch let error as PGNSerializationError {
        if case let .invalidMoveRecord(.san(expected, actual), context) = error {
            #expect(expected == "f3")
            #expect(actual == "e4")
            #expect(context.ply == 1)
        } else {
            Issue.record("Expected invalidMoveRecord SAN failure, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }

    let missingLastMove = PGNGame(
        tagPairs: checkmate.tagPairs,
        initialPosition: checkmate.initialPosition,
        moveRecords: Array(checkmate.moveRecords.dropLast()),
        result: .unfinished,
        finalPosition: checkmate.finalPosition,
        finalStatus: .ongoing(drawClaims: Set<GameDrawClaim>())
    )

    do {
        _ = try serializer.pgn(from: missingLastMove)
        Issue.record("Expected manually constructed finalPosition mismatch to fail")
    } catch let error as PGNSerializationError {
        if case .finalPositionMismatch = error {
            // Expected.
        } else {
            Issue.record("Expected finalPositionMismatch, got: \(error)")
        }
    } catch {
        Issue.record("Expected PGNSerializationError, got: \(error)")
    }
}

@Test func pgnParsesLichessStandardDatabaseSample() throws {
    let game = try PGNSerializer().game(from: lichessStandardDatabaseSample)

    #expect(game.tagValue(for: "Site") == "https://lichess.org/PpwPOZMq")
    #expect(game.result == .blackWins)
    #expect(game.moveRecords.count == 26)
    #expect(game.moveRecords[0].comments == ["[%eval 0.17] [%clk 0:00:30]"])
    #expect(game.moveRecords[7].san == "b5")
    #expect(game.moveRecords[7].nags.map(\.rawValue) == [2])
    #expect(game.moveRecords[8].san == "Bb3")
    #expect(game.moveRecords[8].nags.map(\.rawValue) == [6])
    #expect(game.moveRecords[20].san == "Nbd2")
    #expect(game.moveRecords[20].nags.map(\.rawValue) == [4])
}

@Test func pgnParsesLichessMiniCorpus() throws {
    let serializer = PGNSerializer()
    let games = try serializer.games(from: lichessMiniCorpus)

    #expect(games.count == 6)
    #expect(games.map { $0.tagValue(for: "Site") } == [
        "https://lichess.org/j1dkb5dw",
        "https://lichess.org/a9tcp02g",
        "https://lichess.org/szom2tog",
        "https://lichess.org/rklpc7mk",
        "https://lichess.org/1xb3os63",
        "https://lichess.org/6x5nq6qd",
    ])
    #expect(games.map(\.result) == [.whiteWins, .whiteWins, .whiteWins, .blackWins, .blackWins, .whiteWins])
    #expect(games.map { $0.moveRecords.count } == [25, 35, 21, 94, 46, 63])
    #expect(games.map { $0.moveRecords.last?.san } == ["Qe8#", "Bxh8", "Nxc7+", "c4", "Bxh3+", "Qxd5+"])

    try assertPGNRoundTrips(games, using: serializer)
}

@Test func pgnParsesExpandedLichessCC0Corpus() throws {
    let serializer = PGNSerializer()
    let games = try serializer.games(from: lichessExpandedCC0Corpus)

    #expect(games.count == 15)
    #expect(games.map { $0.tagValue(for: "Site") } == [
        "https://lichess.org/1hi3aveq",
        "https://lichess.org/6x5okiht",
        "https://lichess.org/pflcg8eb",
        "https://lichess.org/bcqa8u74",
        "https://lichess.org/0i6bq9a9",
        "https://lichess.org/tw3fxgjh",
        "https://lichess.org/gu3wxtnf",
        "https://lichess.org/8hia9meu",
        "https://lichess.org/kvvm7a7d",
        "https://lichess.org/k0dgsn99",
        "https://lichess.org/t2y7ot3b",
        "https://lichess.org/hla57hi7",
        "https://lichess.org/4urpsw2h",
        "https://lichess.org/uuoc3k9j",
        "https://lichess.org/m3oizjhx",
    ])
    #expect(games.map(\.result) == [
        .blackWins, .blackWins, .blackWins, .whiteWins, .blackWins,
        .blackWins, .blackWins, .blackWins, .whiteWins, .blackWins,
        .whiteWins, .whiteWins, .whiteWins, .whiteWins, .blackWins,
    ])
    #expect(games.map { $0.tagValue(for: "Variant") } == Array(repeating: "Standard", count: games.count))
    #expect(games.map { $0.tagValue(for: "GameId") } == [
        "1hi3aveq",
        "6x5okiht",
        "pflcg8eb",
        "bcqa8u74",
        "0i6bq9a9",
        "tw3fxgjh",
        "gu3wxtnf",
        "8hia9meu",
        "kvvm7a7d",
        "k0dgsn99",
        "t2y7ot3b",
        "hla57hi7",
        "4urpsw2h",
        "uuoc3k9j",
        "m3oizjhx",
    ])

    let allSAN = games.flatMap { $0.moveRecords.map(\.san) }
    #expect(allSAN.contains("c8=Q"))
    #expect(allSAN.contains("d1=Q"))
    #expect(allSAN.contains("e1=Q"))
    #expect(allSAN.contains("Q4g4#"))
    #expect(allSAN.contains("h1=Q"))
    #expect(allSAN.contains("a1=Q"))
    #expect(allSAN.contains("Qag1#"))
    #expect(allSAN.contains("O-O-O"))

    #expect(games.allSatisfy { $0.resultMatchesFinalStatus })
    #expect(games.contains { $0.requiredResultForFinalStatus == .whiteWins })
    #expect(games.contains { $0.requiredResultForFinalStatus == .blackWins })
    #expect(games.contains { $0.requiredResultForFinalStatus == nil && $0.result != .unfinished })
    #expect(games.filter { $0.tagValue(for: "Termination") == "Time forfeit" }.count == 1)

    try assertPGNRoundTrips(games, using: serializer)
}

@Test(
    "Generated legal PGN round trips",
    arguments: Array(0..<20)
)
func pgnGeneratedLegalGamesRoundTrip(seed: Int) throws {
    let serializer = PGNSerializer()
    let moves = generatedLegalMainline(seed: seed, maxPlies: 48)
    let fallbackResult: PGNResult = seed.isMultiple(of: 3) ? .draw : .unfinished
    let result = try compatiblePGNResult(for: moves, fallback: fallbackResult)
    let tags = [
        PGNTagPair(name: "Event", value: "Generated Round Trip \(seed)"),
        PGNTagPair(name: "Round", value: "\(seed + 1)"),
    ]

    let exported = try serializer.pgn(moves: moves, tags: tags, result: result, lineWidth: 64)
    let reparsed = try serializer.game(from: exported)

    #expect(moves.count == 48)
    #expect(reparsed.mainlineMoves == moves)
    #expect(reparsed.result == result)
}

@Test func pgnParsesAdditionalSANDisambiguationCases() throws {
    let cases = [
        (
            "4k3/8/8/8/8/8/4K3/R6R w - - 0 1",
            "Rad1",
            "a1d1"
        ),
        (
            "4k3/8/8/8/8/8/4K3/R6R w - - 0 1",
            "Rhd1",
            "h1d1"
        ),
        (
            "R7/8/7k/8/8/8/4K3/R7 w - - 0 1",
            "R1a4",
            "a1a4"
        ),
        (
            "R7/8/7k/8/8/8/4K3/R7 w - - 0 1",
            "R8a4",
            "a8a4"
        ),
        (
            "1k6/8/8/8/Q6Q/8/8/4K3 w - - 0 1",
            "Qad4",
            "a4d4"
        ),
        (
            "1k6/8/8/8/Q6Q/8/8/4K3 w - - 0 1",
            "Qhd4",
            "h4d4"
        ),
        (
            "7k/8/8/8/8/8/B5B1/4K3 w - - 0 1",
            "Bad5",
            "a2d5"
        ),
        (
            "7k/8/8/8/8/8/B5B1/4K3 w - - 0 1",
            "Bgd5",
            "g2d5"
        ),
        (
            "7k/8/1N6/8/8/8/1N1N4/4K3 w - - 0 1",
            "Nb2c4",
            "b2c4"
        ),
    ]

    for (fen, san, move) in cases {
        let pgn = """
            [Event "Synthetic Ambiguity"]
            [Site "?"]
            [Date "????.??.??"]
            [Round "?"]
            [White "White"]
            [Black "Black"]
            [Result "1/2-1/2"]
            [SetUp "1"]
            [FEN "\(fen)"]

            1. \(san) 1/2-1/2
            """
        let game = try PGNSerializer().game(from: pgn)
        #expect(game.moveRecords.map(\.san) == [san])
        #expect(game.mainlineMoves.map(\.description) == [move])
    }
}

@Test func pgnToleratesCompactMovetextEscapeLinesAndSemicolonComments() throws {
    let pgn = """
        % Imported by a PGN tool; escape lines should be ignored.
        [Event "Tolerance"]
        [Site "?"]
        [Date "????.??.??"]
        [Round "?"]
        [White "White"]
        [Black "Black"]
        [Result "*"]

        { comment before the first move is tolerated }
        1.e4; line comment after white's move
        1...e5 2.Nf3{brace comment without surrounding whitespace}Nc6 *
        { trailing database comment }
        """

    let game = try PGNSerializer().game(from: pgn)

    #expect(game.moveRecords.map(\.san) == ["e4", "e5", "Nf3", "Nc6"])
    #expect(game.moveRecords[0].comments == ["line comment after white's move"])
    #expect(game.moveRecords[2].comments == ["brace comment without surrounding whitespace"])
}

@Test(
    "Long deterministic PGN stress round trips",
    arguments: Array(100..<110)
)
func pgnLongGeneratedGamesStressRoundTrip(seed: Int) throws {
    let serializer = PGNSerializer()
    let moves = generatedLegalMainline(seed: seed, maxPlies: 160)
    let fallbackResult: PGNResult = seed.isMultiple(of: 2) ? .whiteWins : .blackWins
    let result = try compatiblePGNResult(for: moves, fallback: fallbackResult)
    let tags = [
        PGNTagPair(name: "Event", value: "Long Generated Stress \(seed)"),
        PGNTagPair(name: "Site", value: "Local"),
    ]

    let exported = try serializer.pgn(moves: moves, tags: tags, result: result, lineWidth: 48)
    let reparsed = try serializer.game(from: exported)
    let builtGame = try serializer.game(moves: moves, result: result)

    #expect(moves.count >= 100)
    #expect(reparsed.mainlineMoves == moves)
    #expect(reparsed.finalPosition == builtGame.finalPosition)
    #expect(reparsed.result == result)
}

private enum PGNStatusSource: Sendable {
    case fen(String)
    case movetext(String)
}

private struct PGNStatusCase: Sendable {
    var name: String
    var source: PGNStatusSource
    var expectedStatus: GameStatus
    var requiredResult: PGNResult?
}

private struct PGNStatusResultCase: Sendable {
    var name: String
    var source: PGNStatusSource
    var result: PGNResult
    var expectedStatus: GameStatus
    var requiredResult: PGNResult?

    var pgn: String {
        statusTestPGN(name: name, source: source, result: result)
    }
}

private let terminalStatusPGNCases = [
    PGNStatusCase(
        name: "White checkmates from FEN",
        source: .fen("7k/6Q1/5K2/8/8/8/8/8 b - - 0 1"),
        expectedStatus: .checkmate(winner: .white),
        requiredResult: .whiteWins
    ),
    PGNStatusCase(
        name: "Black checkmates from FEN",
        source: .fen("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"),
        expectedStatus: .checkmate(winner: .black),
        requiredResult: .blackWins
    ),
    PGNStatusCase(
        name: "Stalemate from FEN",
        source: .fen("7k/5K2/6Q1/8/8/8/8/8 b - - 0 1"),
        expectedStatus: .draw(.stalemate),
        requiredResult: .draw
    ),
    PGNStatusCase(
        name: "Bare kings insufficient material",
        source: .fen("8/8/8/8/8/8/8/K6k w - - 0 1"),
        expectedStatus: .draw(.insufficientMaterial),
        requiredResult: .draw
    ),
    PGNStatusCase(
        name: "Same-color bishops insufficient material",
        source: .fen("8/8/8/8/8/8/3b4/K1k1B1B1 w - - 0 1"),
        expectedStatus: .draw(.insufficientMaterial),
        requiredResult: .draw
    ),
    PGNStatusCase(
        name: "Sealed pawn-barrier dead position",
        source: .fen("7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"),
        expectedStatus: .draw(.deadPosition),
        requiredResult: .draw
    ),
    PGNStatusCase(
        name: "Seventy-five-move automatic draw",
        source: .fen("4k3/8/8/8/8/8/Q7/4K3 w - - 150 1"),
        expectedStatus: .draw(.seventyFiveMoveRule),
        requiredResult: .draw
    ),
    PGNStatusCase(
        name: "White checkmates from movetext",
        source: .movetext("1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7#"),
        expectedStatus: .checkmate(winner: .white),
        requiredResult: .whiteWins
    ),
    PGNStatusCase(
        name: "Black checkmates from movetext",
        source: .movetext("1. f3 e5 2. g4 Qh4#"),
        expectedStatus: .checkmate(winner: .black),
        requiredResult: .blackWins
    ),
    PGNStatusCase(
        name: "Fivefold repetition automatic draw",
        source: .movetext(
            "1. Nf3 Nf6 2. Ng1 Ng8 3. Nf3 Nf6 4. Ng1 Ng8 5. Nf3 Nf6 6. Ng1 Ng8 7. Nf3 Nf6 8. Ng1 Ng8"
        ),
        expectedStatus: .draw(.fivefoldRepetition),
        requiredResult: .draw
    ),
]

private let ongoingStatusPGNCases = [
    PGNStatusCase(
        name: "Normal ongoing movetext",
        source: .movetext("1. e4"),
        expectedStatus: .ongoing(drawClaims: Set<GameDrawClaim>()),
        requiredResult: nil
    ),
    PGNStatusCase(
        name: "Ongoing position with fifty-move claim",
        source: .fen("4k3/8/8/8/8/8/Q7/4K3 w - - 100 1"),
        expectedStatus: .ongoing(drawClaims: Set<GameDrawClaim>([.fiftyMoveRule])),
        requiredResult: nil
    ),
    PGNStatusCase(
        name: "Ongoing position with threefold claim",
        source: .movetext("1. Nf3 Nf6 2. Ng1 Ng8 3. Nf3 Nf6 4. Ng1 Ng8"),
        expectedStatus: .ongoing(drawClaims: Set<GameDrawClaim>([.threefoldRepetition])),
        requiredResult: nil
    ),
    PGNStatusCase(
        name: "Ongoing check with legal en-passant evasion",
        source: .fen("4k3/8/8/3pP3/4K3/8/8/8 w - d6 0 1"),
        expectedStatus: .ongoing(drawClaims: Set<GameDrawClaim>()),
        requiredResult: nil
    ),
]

private let terminalStatusAcceptedResultCases = terminalStatusPGNCases.compactMap { testCase in
    testCase.requiredResult.map { result in
        PGNStatusResultCase(
            name: testCase.name,
            source: testCase.source,
            result: result,
            expectedStatus: testCase.expectedStatus,
            requiredResult: testCase.requiredResult
        )
    }
}

private let terminalStatusRejectedResultCases = terminalStatusPGNCases.flatMap { testCase in
    PGNResult.allCases
        .filter { $0 != testCase.requiredResult }
        .map { result in
            PGNStatusResultCase(
                name: "\(testCase.name), rejected \(result.rawValue)",
                source: testCase.source,
                result: result,
                expectedStatus: testCase.expectedStatus,
                requiredResult: testCase.requiredResult
            )
        }
}

private let ongoingStatusAcceptedResultCases = ongoingStatusPGNCases.flatMap { testCase in
    PGNResult.allCases.map { result in
        PGNStatusResultCase(
            name: "\(testCase.name), accepted \(result.rawValue)",
            source: testCase.source,
            result: result,
            expectedStatus: testCase.expectedStatus,
            requiredResult: nil
        )
    }
}

private func statusTestPGN(name: String, source: PGNStatusSource, result: PGNResult) -> String {
    switch source {
    case let .fen(fen):
        return """
            [Event "\(name)"]
            [Site "?"]
            [Date "????.??.??"]
            [Round "?"]
            [White "White"]
            [Black "Black"]
            [Result "\(result.rawValue)"]
            [SetUp "1"]
            [FEN "\(fen)"]

            \(result.rawValue)
            """
    case let .movetext(movetext):
        return """
            [Event "\(name)"]
            [Site "?"]
            [Date "????.??.??"]
            [Round "?"]
            [White "White"]
            [Black "Black"]
            [Result "\(result.rawValue)"]

            \(movetext) \(result.rawValue)
            """
    }
}

private func exportedPGN(for testCase: PGNStatusResultCase) throws -> String {
    let serializer = PGNSerializer()

    switch testCase.source {
    case let .fen(fen):
        return try serializer.pgn(
            initialPosition: try FENSerializer().position(from: fen),
            moves: [],
            result: testCase.result
        )
    case .movetext:
        let parseResult = testCase.requiredResult ?? testCase.result
        let validGame = try serializer.game(from: statusTestPGN(
            name: testCase.name,
            source: testCase.source,
            result: parseResult
        ))
        return try serializer.pgn(
            initialPosition: validGame.initialPosition,
            moves: validGame.mainlineMoves,
            result: testCase.result
        )
    }
}

private func expectPGNParsingError(
    _ pgn: String,
    parseSingleGame: Bool = false,
    matches: (PGNParsingError) -> Bool
) {
    do {
        if parseSingleGame {
            _ = try PGNSerializer().game(from: pgn)
        } else {
            _ = try PGNSerializer().games(from: pgn)
        }
        Issue.record("Expected PGN parsing to fail")
    } catch let error as PGNParsingError {
        #expect(matches(error))
    } catch {
        Issue.record("Expected PGNParsingError, got: \(error)")
    }
}

private func generatedLegalMainline(seed: Int, maxPlies: Int) -> [Move] {
    let game = Game(position: try! FENSerializer().position(from: PGNSerializer.standardStartingFEN))
    var generator = DeterministicGenerator(seed: UInt64(seed + 1))
    var moves: [Move] = []

    for _ in 0..<maxPlies {
        let legalMoves = game.legalMoves.sorted { $0.description < $1.description }
        guard !legalMoves.isEmpty else {
            break
        }
        let move = legalMoves[generator.nextIndex(upperBound: legalMoves.count)]
        moves.append(move)
        game.apply(move: move)
    }

    return moves
}

private func compatiblePGNResult(for moves: [Move], fallback: PGNResult) throws -> PGNResult {
    let startingPosition = try FENSerializer().position(from: PGNSerializer.standardStartingFEN)
    let game = try Game.replay(initialPosition: startingPosition, moves: moves)

    switch game.status {
    case .ongoing:
        return fallback
    case let .checkmate(winner):
        return winner == .white ? .whiteWins : .blackWins
    case .draw:
        return .draw
    }
}

private func assertPGNRoundTrips(_ games: [PGNGame], using serializer: PGNSerializer) throws {
    for game in games {
        let reparsed = try serializer.game(from: try serializer.pgn(from: game))
        for tagPair in game.tagPairs {
            #expect(reparsed.tagValue(for: tagPair.name) == tagPair.value)
        }
        #expect(reparsed.mainlineMoves == game.mainlineMoves)
        #expect(reparsed.finalPosition == game.finalPosition)
        #expect(reparsed.finalStatus == game.finalStatus)
        #expect(reparsed.result == game.result)
        #expect(reparsed.resultMatchesFinalStatus == game.resultMatchesFinalStatus)
    }
}

private struct DeterministicGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9e37_79b9_7f4a_7c15
    }

    mutating func nextIndex(upperBound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(state % UInt64(upperBound))
    }
}

private let lichessStandardDatabaseSample = """
    [Event "Rated Bullet tournament https://lichess.org/tournament/yc1WW2Ox"]
    [Site "https://lichess.org/PpwPOZMq"]
    [Date "2017.04.01"]
    [Round "-"]
    [White "Abbot"]
    [Black "Costello"]
    [Result "0-1"]
    [UTCDate "2017.04.01"]
    [UTCTime "11:32:01"]
    [WhiteElo "2100"]
    [BlackElo "2000"]
    [WhiteRatingDiff "-4"]
    [BlackRatingDiff "+1"]
    [WhiteTitle "FM"]
    [ECO "B30"]
    [Opening "Sicilian Defense: Old Sicilian"]
    [TimeControl "300+0"]
    [Termination "Time forfeit"]

    1. e4 { [%eval 0.17] [%clk 0:00:30] } 1... c5 { [%eval 0.19] [%clk 0:00:30] }
    2. Nf3 { [%eval 0.25] [%clk 0:00:29] } 2... Nc6 { [%eval 0.33] [%clk 0:00:30] }
    3. Bc4 { [%eval -0.13] [%clk 0:00:28] } 3... e6 { [%eval -0.04] [%clk 0:00:30] }
    4. c3 { [%eval -0.4] [%clk 0:00:27] } 4... b5? { [%eval 1.18] [%clk 0:00:30] }
    5. Bb3?! { [%eval 0.21] [%clk 0:00:26] } 5... c4 { [%eval 0.32] [%clk 0:00:29] }
    6. Bc2 { [%eval 0.2] [%clk 0:00:25] } 6... a5 { [%eval 0.6] [%clk 0:00:29] }
    7. d4 { [%eval 0.29] [%clk 0:00:23] } 7... cxd3 { [%eval 0.6] [%clk 0:00:27] }
    8. Qxd3 { [%eval 0.12] [%clk 0:00:22] } 8... Nf6 { [%eval 0.52] [%clk 0:00:26] }
    9. e5 { [%eval 0.39] [%clk 0:00:21] } 9... Nd5 { [%eval 0.45] [%clk 0:00:25] }
    10. Bg5?! { [%eval -0.44] [%clk 0:00:18] } 10... Qc7 { [%eval -0.12] [%clk 0:00:23] }
    11. Nbd2?? { [%eval -3.15] [%clk 0:00:14] } 11... h6 { [%eval -2.99] [%clk 0:00:23] }
    12. Bh4 { [%eval -3.0] [%clk 0:00:11] } 12... Ba6? { [%eval -0.12] [%clk 0:00:23] }
    13. b3?? { [%eval -4.14] [%clk 0:00:02] } 13... Nf4? { [%eval -2.73] [%clk 0:00:21] } 0-1
    """

private let lichessMiniCorpus = """
    [Event "Rated Classical game"]
    [Site "https://lichess.org/j1dkb5dw"]
    [White "BFG9k"]
    [Black "mamalak"]
    [Result "1-0"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:01:03"]
    [WhiteElo "1639"]
    [BlackElo "1403"]
    [WhiteRatingDiff "+5"]
    [BlackRatingDiff "-8"]
    [ECO "C00"]
    [Opening "French Defense: Normal Variation"]
    [TimeControl "600+8"]
    [Termination "Normal"]

    1. e4 e6 2. d4 b6 3. a3 Bb7 4. Nc3 Nh6 5. Bxh6 gxh6 6. Be2 Qg5 7. Bg4 h5 8. Nf3 Qg6 9. Nh4 Qg5 10. Bxh5 Qxh4 11. Qf3 Kd8 12. Qxf7 Nc6 13. Qe8# 1-0

    [Event "Rated Classical game"]
    [Site "https://lichess.org/a9tcp02g"]
    [White "Desmond_Wilson"]
    [Black "savinka59"]
    [Result "1-0"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:04:12"]
    [WhiteElo "1654"]
    [BlackElo "1919"]
    [WhiteRatingDiff "+19"]
    [BlackRatingDiff "-22"]
    [ECO "D04"]
    [Opening "Queen's Pawn Game: Colle System, Anti-Colle"]
    [TimeControl "480+2"]
    [Termination "Normal"]

    1. d4 d5 2. Nf3 Nf6 3. e3 Bf5 4. Nh4 Bg6 5. Nxg6 hxg6 6. Nd2 e6 7. Bd3 Bd6 8. e4 dxe4 9. Nxe4 Rxh2 10. Ke2 Rxh1 11. Qxh1 Nc6 12. Bg5 Ke7 13. Qh7 Nxd4+ 14. Kd2 Qe8 15. Qxg7 Qh8 16. Bxf6+ Kd7 17. Qxh8 Rxh8 18. Bxh8 1-0

    [Event "Rated Classical game"]
    [Site "https://lichess.org/szom2tog"]
    [White "Kozakmamay007"]
    [Black "VanillaShamanilla"]
    [Result "1-0"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:03:15"]
    [WhiteElo "1643"]
    [BlackElo "1747"]
    [WhiteRatingDiff "+13"]
    [BlackRatingDiff "-94"]
    [ECO "C50"]
    [Opening "Four Knights Game: Italian Variation"]
    [TimeControl "420+17"]
    [Termination "Normal"]

    1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Nc3 Bc5 5. a3 Bxf2+ 6. Kxf2 Nd4 7. d3 Ng4+ 8. Kf1 Qf6 9. h3 d5 10. Nxd5 Qe6 11. Nxc7+ 1-0

    [Event "Rated Bullet game"]
    [Site "https://lichess.org/rklpc7mk"]
    [White "Naitero_Nagasaki"]
    [Black "800"]
    [Result "0-1"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:04:57"]
    [WhiteElo "1824"]
    [BlackElo "1973"]
    [WhiteRatingDiff "-6"]
    [BlackRatingDiff "+8"]
    [ECO "B12"]
    [Opening "Caro-Kann Defense: Goldman Variation"]
    [TimeControl "60+1"]
    [Termination "Normal"]

    1. e4 c6 2. Nc3 d5 3. Qf3 dxe4 4. Nxe4 Nd7 5. Bc4 Ngf6 6. Nxf6+ Nxf6 7. Qg3 Bf5 8. d3 Bg6 9. Ne2 e6 10. Bf4 Nh5 11. Qf3 Nxf4 12. Nxf4 Be7 13. Bxe6 fxe6 14. Nxe6 Qa5+ 15. c3 Qe5+ 16. Qe3 Qxe3+ 17. fxe3 Kd7 18. Nf4 Bd6 19. Nxg6 hxg6 20. h3 Bg3+ 21. Kd2 Raf8 22. Rhf1 Ke7 23. d4 Rxf1 24. Rxf1 Rf8 25. Rxf8 Kxf8 26. e4 Ke7 27. Ke3 g5 28. Kf3 Be1 29. Kg4 Bd2 30. Kf5 Bc1 31. Kg6 Kf8 32. e5 Bxb2 33. Kxg5 Bxc3 34. h4 Bxd4 35. h5 Bxe5 36. g4 Bb2 37. Kf5 Kf7 38. g5 Bc1 39. g6+ Ke7 40. Ke5 b5 41. Kd4 Kd6 42. Kc3 c5 43. a3 Bg5 44. a4 bxa4 45. Kb2 Kd5 46. Ka3 Kd4 47. Kxa4 c4 0-1

    [Event "Rated Bullet game"]
    [Site "https://lichess.org/1xb3os63"]
    [White "nichiren1967"]
    [Black "Naitero_Nagasaki"]
    [Result "0-1"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:02:37"]
    [WhiteElo "1765"]
    [BlackElo "1815"]
    [WhiteRatingDiff "-9"]
    [BlackRatingDiff "+9"]
    [ECO "C00"]
    [Opening "French Defense: La Bourdonnais Variation"]
    [TimeControl "60+1"]
    [Termination "Normal"]

    1. e4 e6 2. f4 d5 3. e5 c5 4. Nf3 Qb6 5. c3 Nc6 6. d3 Bd7 7. Be2 Nh6 8. O-O Nf5 9. g4 Nh6 10. Kg2 Nxg4 11. h3 Nh6 12. Ng5 Nf5 13. Bg4 Nce7 14. Nd2 Ne3+ 15. Kf3 Nxd1 16. Rxd1 h6 17. Nxf7 Kxf7 18. Rf1 h5 19. Bxe6+ Bxe6 20. Kg3 Nf5+ 21. Kg2 Ne3+ 22. Kf2 Nxf1 23. Kxf1 Bxh3+ 0-1

    [Event "Rated Blitz game"]
    [Site "https://lichess.org/6x5nq6qd"]
    [White "sport"]
    [Black "shamirbj"]
    [Result "1-0"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:09:21"]
    [WhiteElo "1477"]
    [BlackElo "1487"]
    [WhiteRatingDiff "+12"]
    [BlackRatingDiff "-11"]
    [ECO "B00"]
    [Opening "Owen Defense"]
    [TimeControl "300+3"]
    [Termination "Time forfeit"]

    1. e4 b6 2. Bc4 Bb7 3. d3 Nh6 4. Bxh6 gxh6 5. Qf3 e6 6. Nh3 Bg7 7. c3 Nc6 8. Qg3 Rg8 9. Qf3 Ne5 10. Qe3 Nxc4 11. dxc4 Qe7 12. O-O Qc5 13. Qxc5 b5 14. Qxb5 Bxe4 15. Nd2 Bc6 16. Qb3 Bxc3 17. g3 Bxd2 18. Rad1 Bg5 19. Nxg5 hxg5 20. Qd3 h6 21. b4 Ba4 22. Rd2 Rb8 23. b5 d6 24. Qa3 Bxb5 25. cxb5 Rxb5 26. Qxa7 Rc5 27. Qa8+ Ke7 28. Qxg8 e5 29. Qh8 d5 30. Qxe5+ Kd7 31. Rxd5+ Rxd5 32. Qxd5+ 1-0
    """

// Public Lichess CC0 standard-game exports, fetched once and checked in so the
// test suite never depends on network access.
private let lichessExpandedCC0Corpus = """
    [Event "rated rapid game"]
    [Site "https://lichess.org/1hi3aveq"]
    [Date "2012.12.31"]
    [Round "-"]
    [White "BFG9k"]
    [Black "Sagaz"]
    [Result "0-1"]
    [GameId "1hi3aveq"]
    [UTCDate "2012.12.31"]
    [UTCTime "23:07:33"]
    [WhiteElo "1644"]
    [BlackElo "1544"]
    [WhiteRatingDiff "-16"]
    [BlackRatingDiff "+14"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B06"]
    [Opening "Modern Defense"]
    [Termination "Normal"]

    1. e4 g6 2. d4 d6 3. Nf3 c6 4. h3 Nf6 5. Bg5 Nxe4 6. Qe2 Bf5 7. Nbd2 Qa5 8. c3 Nxd2 9. Bxd2 Nd7 10. b4 Qa3 11. Ng5 h5 12. Qc4 d5 13. Qe2 Qb2 14. Qd1 Bc2 15. Qc1 Qxc1+ 16. Rxc1 Ba4 17. Bd3 Nb6 18. O-O Nc4 19. Bxc4 dxc4 20. Bf4 Bh6 21. Rfe1 O-O 22. Rxe7 Rae8 23. Rxb7 f6 24. Ne6 Rxe6 25. Bxh6 Rf7 26. Rb8+ Kh7 27. Bf4 g5 28. Bd2 Re2 29. Be1 Rfe7 30. Kf1 Bc2 31. Rc8 Bd3 32. Rxc6 Rc2+ 33. Kg1 Rxc1 34. Rxf6 h4 35. g4 Rexe1+ 36. Kg2 Be4+ 37. f3 Rc2# 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/6x5okiht"]
    [Date "2012.12.31"]
    [Round "-"]
    [White "BFG9k"]
    [Black "Jonathan_52"]
    [Result "0-1"]
    [GameId "6x5okiht"]
    [UTCDate "2012.12.31"]
    [UTCTime "22:48:41"]
    [WhiteElo "1649"]
    [BlackElo "1500"]
    [WhiteRatingDiff "-10"]
    [BlackRatingDiff "+265"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B00"]
    [Opening "Nimzowitsch Defense: Mikenas Variation"]
    [Termination "Normal"]

    1. e4 Nc6 2. d4 d6 3. Bb5 e5 4. d5 a6 5. dxc6 axb5 6. cxb7 Bxb7 7. Nc3 Nf6 8. Bg5 h6 9. Bh4 g5 10. Bg3 b4 11. Nd5 Bxd5 12. exd5 Ne4 13. Ne2 c6 14. dxc6 Qc7 15. Qd5 Ra5 16. Qxe4 h5 17. Qxb4 d5 18. Bxe5 Qxe5 19. Qxa5 Qe4 20. Qa8+ Ke7 21. Qb7+ Ke6 22. Qd7+ Kf6 23. Qd8+ Kg6 24. c7 Bg7 25. Qxh8 Bxh8 26. c8=Q Kh7 27. Qh3 g4 28. Qxh5+ Kg8 29. Qg5+ Bg7 30. h3 Qxg2 31. O-O-O Qxf2 32. Qxg4 Qe3+ 33. Kb1 Qe5 34. Rhg1 Qxb2# 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/pflcg8eb"]
    [Date "2012.12.31"]
    [Round "-"]
    [White "BFG9k"]
    [Black "arion_6"]
    [Result "0-1"]
    [GameId "pflcg8eb"]
    [UTCDate "2012.12.31"]
    [UTCTime "22:42:26"]
    [WhiteElo "1659"]
    [BlackElo "1500"]
    [WhiteRatingDiff "-10"]
    [BlackRatingDiff "+273"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C23"]
    [Opening "Bishop's Opening: Philidor Counterattack"]
    [Termination "Normal"]

    1. e4 e5 2. Bc4 c6 3. d3 d5 4. exd5 cxd5 5. Bb5+ Nc6 6. Nf3 Bg4 7. h3 Bh5 8. Bg5 Bxf3 9. Qxf3 Qxg5 10. Qxd5 Qc1+ 11. Ke2 Qxc2+ 12. Kf3 Nf6 13. Qxe5+ Be7 14. Re1 O-O 15. Bxc6 Qxc6+ 16. Kg3 Bd6 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/bcqa8u74"]
    [Date "2012.12.30"]
    [Round "-"]
    [White "BFG9k"]
    [Black "A4"]
    [Result "1-0"]
    [GameId "bcqa8u74"]
    [UTCDate "2012.12.30"]
    [UTCTime "21:57:38"]
    [WhiteElo "1644"]
    [BlackElo "1764"]
    [WhiteRatingDiff "+15"]
    [BlackRatingDiff "-35"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C00"]
    [Opening "Rat Defense: Small Center Defense"]
    [Termination "Normal"]

    1. e4 e6 2. d4 d6 3. Nf3 c6 4. Nc3 f6 5. Bf4 g6 6. Bc4 h6 7. O-O b6 8. h3 a6 9. a3 b5 10. Ba2 g5 11. Bh2 h5 12. Re1 Be7 13. Qd3 e5 14. d5 Nh6 15. dxc6 Nxc6 16. Bd5 Qc7 17. Bxc6+ Qxc6 18. Nd5 g4 19. Nxe7 Kxe7 20. Nh4 gxh3 21. Ng6+ Kf7 22. Nxh8+ Kg7 23. Qg3+ Kxh8 24. Qg6 hxg2 25. Qxh6+ Kg8 26. Qxf6 Bg4 27. Bxe5 Ra7 28. Rad1 Rh7 29. Rxd6 Qe8 30. Rd8 Qxd8 31. Qxd8+ Kf7 32. Qf6+ Kg8 33. Qg6+ Kf8 34. Qxh7 h4 35. Qxh4 Bh3 36. Qxh3 b4 37. Qh7 bxa3 38. Rd1 axb2 39. Rd8# 1-0

    [Event "rated rapid game"]
    [Site "https://lichess.org/0i6bq9a9"]
    [Date "2012.12.30"]
    [Round "-"]
    [White "BFG9k"]
    [Black "Zaqws"]
    [Result "0-1"]
    [GameId "0i6bq9a9"]
    [UTCDate "2012.12.30"]
    [UTCTime "21:30:19"]
    [WhiteElo "1657"]
    [BlackElo "1641"]
    [WhiteRatingDiff "-13"]
    [BlackRatingDiff "+12"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B01"]
    [Opening "Scandinavian Defense"]
    [Termination "Normal"]

    1. e4 d5 2. e5 Bf5 3. d4 e6 4. h3 Ne7 5. Bg5 h6 6. Bh4 g5 7. Bg3 Nbc6 8. Bb5 Qd7 9. Nf3 O-O-O 10. a4 a6 11. Bd3 Nb4 12. Bxf5 Nxf5 13. Bh2 c5 14. c3 Nc6 15. b4 cxd4 16. cxd4 Nxb4 17. Na3 Kb8 18. O-O Rc8 19. Qd2 Be7 20. Rfc1 Rxc1+ 21. Rxc1 Rc8 22. Nc2 Nxc2 23. Rxc2 Qxa4 24. Rxc8+ Kxc8 25. Qc1+ Kb8 26. Bg3 Nxd4 27. Nxd4 Qxd4 28. Kh2 Qc4 29. Qd1 a5 30. Qh5 Qc7 31. Qxf7 Qd7 32. Qg6 a4 33. Qb1 b5 34. f3 h5 35. Be1 h4 36. g4 Qc6 37. Bd2 Qc4 38. Kg1 Bc5+ 39. Kg2 Qe2+ 40. Kh1 Qxf3+ 41. Kh2 Qg3+ 42. Kh1 Qxh3# 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/tw3fxgjh"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "Monsieur_Tapis"]
    [Result "0-1"]
    [GameId "tw3fxgjh"]
    [UTCDate "2012.12.29"]
    [UTCTime "23:49:23"]
    [WhiteElo "1665"]
    [BlackElo "1779"]
    [WhiteRatingDiff "-8"]
    [BlackRatingDiff "+8"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C02"]
    [Opening "French Defense: Advance Variation"]
    [Termination "Normal"]

    1. e4 e6 2. d4 d5 3. e5 c5 4. c3 Nc6 5. Bb5 Bd7 6. Bxc6 bxc6 7. Nf3 cxd4 8. cxd4 c5 9. O-O Nh6 10. Bxh6 gxh6 11. Qd2 Rg8 12. dxc5 Qc7 13. b4 a5 14. a3 axb4 15. Qxb4 Bxc5 16. Qf4 Rg6 17. Rc1 Qa7 18. Rc3 Bxf2+ 19. Kh1 Ke7 20. Qb4+ Ke8 21. Nbd2 Rb8 22. Qd6 Rb6 23. Rc7 Rxd6 24. Rxa7 Rb6 25. Ra8+ Ke7 26. h3 Rc6 27. a4 Rc8 28. Rxc8 Bxc8 29. a5 Ba6 30. Nb3 Kd7 31. Nfd4 Rg3 32. Nc5+ Kc8 33. Nxa6 Bxd4 34. Rc1+ Rc3 35. Rf1 Bxe5 36. Nb4 f6 37. a6 Ra3 38. Kg1 Bd4+ 39. Kh2 Be5+ 40. g3 Bxg3+ 41. Kg2 Be5 42. Rc1+ Rc3 43. Rxc3+ Bxc3 44. Nc6 Be5 45. Ne7+ Kb8 46. Nc6+ Ka8 47. a7 Bc7 48. Kf3 Bb6 49. Kf4 Bxa7 50. Nxa7 Kxa7 51. Ke3 Kb6 52. Kd4 Kc6 53. h4 e5+ 54. Ke3 f5 55. Kf3 Kc5 56. h5 Kc4 57. Kg3 d4 58. Kf3 Kd3 59. Kg3 Ke3 60. Kg2 d3 61. Kf1 Kd2 62. Kf2 e4 63. Kf1 Kc1 64. Ke1 d2+ 65. Kf2 d1=Q 66. Ke3 Qf3+ 67. Kd4 Qd3+ 68. Ke5 Qb5+ 69. Kf4 Kd2 70. Kg3 e3 71. Kg2 e2 72. Kf3 e1=Q 73. Kg2 Qe4+ 74. Kf2 Qbe2+ 75. Kg3 Q4g4# 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/gu3wxtnf"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "Vitus"]
    [Result "0-1"]
    [GameId "gu3wxtnf"]
    [UTCDate "2012.12.29"]
    [UTCTime "23:25:44"]
    [WhiteElo "1678"]
    [BlackElo "1620"]
    [WhiteRatingDiff "-13"]
    [BlackRatingDiff "+13"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B00"]
    [Opening "Duras Gambit"]
    [Termination "Normal"]

    1. e4 f5 2. Qh5+ g6 3. Qf3 d6 4. Bc4 Nf6 5. d3 Nc6 6. Bb5 Bd7 7. Nc3 Nd4 8. Bxd7+ Nxd7 9. Qd1 e5 10. Nf3 Nc6 11. Bg5 Be7 12. Qd2 Bxg5 13. Nxg5 f4 14. Ne6 Qc8 15. Nd5 Kf7 16. Ng5+ Kg8 17. b4 Nf8 18. b5 Qd8 19. bxc6 Qxg5 20. cxb7 Rb8 21. Rg1 Rxb7 22. f3 c6 23. Nc3 Ne6 24. Ne2 Kf7 25. Qc3 Rc8 26. Qc4 Qh4+ 27. g3 fxg3 28. hxg3 Qh2 29. Rf1 Ke7 30. a4 Kd7 31. a5 Rcb8 32. Kd2 Rb4 33. Qa6 R4b7 34. c4 Rb2+ 35. Kc1 Qxe2 36. Qxa7+ Nc7 37. Qf2 Rc2# 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/8hia9meu"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "guzu"]
    [Result "0-1"]
    [GameId "8hia9meu"]
    [UTCDate "2012.12.29"]
    [UTCTime "21:18:27"]
    [WhiteElo "1686"]
    [BlackElo "1832"]
    [WhiteRatingDiff "-8"]
    [BlackRatingDiff "+7"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B20"]
    [Opening "Sicilian Defense: Bowdler Attack"]
    [Termination "Normal"]

    1. e4 c5 2. Bc4 g6 3. d3 Nc6 4. Nf3 Bg7 5. Bg5 Bxb2 6. Nc3 Bxc3+ 7. Nd2 Bxa1 8. Qxa1 Nf6 9. Bxf6 exf6 10. O-O O-O 11. Re1 d6 12. Nf3 Ne5 13. Nxe5 dxe5 14. Bd5 Qc7 15. c4 Bd7 16. Re3 Bc6 17. Rf3 Kg7 18. g4 h6 19. h4 Bxd5 20. cxd5 Qd6 21. g5 fxg5 22. hxg5 h5 23. Rf6 Qd7 24. Qxe5 Qg4+ 25. Kf1 Kg8 26. d6 Qd1+ 27. Kg2 Qxd3 28. Qe7 Rae8 29. Qxb7 Qxe4+ 30. Qxe4 Rxe4 31. d7 Rd4 32. Rc6 c4 33. Rc8 Rxd7 34. Rxc4 Rd5 35. f4 Rd2+ 36. Kf3 Rxa2 37. Ke4 Re8+ 38. Kd5 Rd2+ 39. Kc5 Rc8+ 40. Kb5 Rxc4 41. Kxc4 a5 42. Kb3 h4 43. f5 h3 44. fxg6 fxg6 45. Kc3 Rd8 46. Kb3 h2 47. Ka4 Ra8 48. Kb5 Kf7 49. Kc5 Ke6 50. Kd4 a4 51. Ke3 Kf5 52. Kf3 Kxg5 53. Kg2 Rh8 54. Kh1 a3 55. Kg2 a2 56. Kg3 h1=Q 57. Kf2 a1=Q 58. Kg3 Qag1# 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/kvvm7a7d"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "MaxPax"]
    [Result "1-0"]
    [GameId "kvvm7a7d"]
    [UTCDate "2012.12.29"]
    [UTCTime "21:06:11"]
    [WhiteElo "1677"]
    [BlackElo "1579"]
    [WhiteRatingDiff "+9"]
    [BlackRatingDiff "-8"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C24"]
    [Opening "Bishop's Opening: Vienna Hybrid"]
    [Termination "Time forfeit"]

    1. e4 e5 2. Bc4 Nf6 3. Nc3 Nc6 4. d3 h6 5. Nd5 Na5 6. Ne3 Nxc4 7. Nxc4 Bc5 8. Nxe5 d6 9. Nc4 Ng4 10. Nh3 Qf6 11. Qe2 1-0

    [Event "rated rapid game"]
    [Site "https://lichess.org/k0dgsn99"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "fistfullofbastard"]
    [Result "0-1"]
    [GameId "k0dgsn99"]
    [UTCDate "2012.12.29"]
    [UTCTime "20:59:43"]
    [WhiteElo "1693"]
    [BlackElo "1550"]
    [WhiteRatingDiff "-16"]
    [BlackRatingDiff "+17"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B12"]
    [Opening "Caro-Kann Defense"]
    [Termination "Normal"]

    1. e4 c6 2. d4 e6 3. Nc3 a6 4. Nf3 h6 5. Bf4 d6 6. Bc4 b5 7. Bb3 Nd7 8. O-O Bb7 9. Re1 d5 10. e5 c5 11. Ne2 c4 12. c3 cxb3 13. Qxb3 Nb6 14. a3 Nc4 15. a4 Ne7 16. axb5 axb5 17. Qxb5+ Bc6 18. Rxa8 Qxa8 19. Qb6 Nxb6 0-1

    [Event "rated rapid game"]
    [Site "https://lichess.org/t2y7ot3b"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "ticotico"]
    [Result "1-0"]
    [GameId "t2y7ot3b"]
    [UTCDate "2012.12.29"]
    [UTCTime "20:35:33"]
    [WhiteElo "1680"]
    [BlackElo "1777"]
    [WhiteRatingDiff "+13"]
    [BlackRatingDiff "-74"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C23"]
    [Opening "Bishop's Opening"]
    [Termination "Normal"]

    1. e4 e5 2. Bc4 d6 3. d3 Be6 4. Bxe6 fxe6 5. Qg4 Qf6 6. Bg5 Qg6 7. h4 h5 8. Qh3 Be7 9. Nf3 Nf6 10. Qxe6 Nbd7 11. Nc3 Qf7 12. Qxf7+ Kxf7 13. Bxf6 Bxf6 14. Nd5 Rhf8 15. Nxc7 Rac8 16. Nb5 Rxc2 17. Nxd6+ Ke6 18. Nxb7 Rxb2 19. Na5 Rfb8 20. O-O g5 21. hxg5 Bg7 22. Nc6 Nc5 23. Nxb8 Rxb8 24. d4 exd4 25. Rad1 Nxe4 26. Nxd4+ Bxd4 27. Rxd4 Ke5 28. Rfd1 Rf8 29. Rd5+ Kf4 30. g3+ Kg4 31. R1d4 Kf3 32. Rd3+ Ke2 33. Re3# 1-0

    [Event "rated rapid game"]
    [Site "https://lichess.org/hla57hi7"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "ticotico"]
    [Result "1-0"]
    [GameId "hla57hi7"]
    [UTCDate "2012.12.29"]
    [UTCTime "20:06:27"]
    [WhiteElo "1663"]
    [BlackElo "1883"]
    [WhiteRatingDiff "+17"]
    [BlackRatingDiff "-106"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C23"]
    [Opening "Bishop's Opening"]
    [Termination "Normal"]

    1. e4 e5 2. Bc4 d6 3. d3 c5 4. Nc3 b6 5. Bd5 Na6 6. Bxa8 Nb4 7. Bd5 Nxd5 8. Nxd5 Be6 9. c4 g6 10. Nf3 Bg7 11. h3 Nf6 12. Bg5 O-O 13. a4 a5 14. Nh2 Bxd5 15. cxd5 Qd7 16. Qf3 Nh5 17. Ng4 f5 18. Nh6+ Kh8 19. exf5 Bf6 20. fxg6 hxg6 21. Bxf6+ Rxf6 22. Qg4 Qg7 23. Qc8+ Rf8 24. Qc6 Qxh6 25. Qxd6 Qf4 26. O-O g5 27. Rae1 g4 28. Qxe5+ Ng7 29. Qxf4 Rxf4 30. Re4 Rf5 31. Rxg4 Rxd5 32. Rg6 Rxd3 33. Rxb6 c4 34. Rc1 Nh5 35. Rh6+ Kg7 36. Rxh5 Rb3 37. Rxc4 Rxb2 38. Rg4+ Kf6 39. Rh6+ Kf5 40. Rh5+ Kf6 41. Rxa5 Rb1+ 42. Kh2 Rb2 43. f3 1-0

    [Event "rated rapid game"]
    [Site "https://lichess.org/4urpsw2h"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "ThreeFoxes"]
    [Result "1-0"]
    [GameId "4urpsw2h"]
    [UTCDate "2012.12.29"]
    [UTCTime "19:54:28"]
    [WhiteElo "1658"]
    [BlackElo "1427"]
    [WhiteRatingDiff "+5"]
    [BlackRatingDiff "-5"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C23"]
    [Opening "Bishop's Opening"]
    [Termination "Normal"]

    1. e4 e5 2. Bc4 d6 3. d3 a6 4. Nf3 h6 5. h3 Nf6 6. Nc3 c6 7. O-O d5 8. Bb3 Qd6 9. Re1 d4 10. Na4 b5 11. Nb6 Ra7 12. Nxc8 Qc7 13. Nxa7 Qxa7 14. Nxe5 Qe7 15. Bxf7+ Kd8 16. Bf4 g5 17. Bg3 h5 18. Ng6 1-0

    [Event "rated rapid game"]
    [Site "https://lichess.org/uuoc3k9j"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "Patolino"]
    [Result "1-0"]
    [GameId "uuoc3k9j"]
    [UTCDate "2012.12.29"]
    [UTCTime "19:27:26"]
    [WhiteElo "1651"]
    [BlackElo "1493"]
    [WhiteRatingDiff "+7"]
    [BlackRatingDiff "-6"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "B00"]
    [Opening "Pirc Defense"]
    [Termination "Normal"]

    1. e4 d6 2. d4 b6 3. Nc3 Bb7 4. Nf3 e6 5. Bg5 Be7 6. Qd2 h6 7. Bf4 g5 8. Bg3 Nf6 9. h3 Qd7 10. Bd3 Nh5 11. Bh2 Bf6 12. g4 Ng7 13. O-O-O O-O 14. Rde1 c5 15. Bb5 Qc7 16. d5 e5 17. Bg3 a5 18. h4 Qc8 19. hxg5 Qxg4 20. gxf6 Qxf3 21. fxg7 1-0

    [Event "rated rapid game"]
    [Site "https://lichess.org/m3oizjhx"]
    [Date "2012.12.29"]
    [Round "-"]
    [White "BFG9k"]
    [Black "parsh"]
    [Result "0-1"]
    [GameId "m3oizjhx"]
    [UTCDate "2012.12.29"]
    [UTCTime "16:00:26"]
    [WhiteElo "1662"]
    [BlackElo "1695"]
    [WhiteRatingDiff "-11"]
    [BlackRatingDiff "+10"]
    [Variant "Standard"]
    [TimeControl "600+8"]
    [ECO "C23"]
    [Opening "Bishop's Opening: Boi Variation"]
    [Termination "Normal"]

    1. e4 e5 2. Bc4 Bc5 3. d3 Nc6 4. Nc3 Nge7 5. Bg5 f6 6. Bh4 Na5 7. Qh5+ Ng6 8. Nf3 Nxc4 9. dxc4 Be7 10. Nd5 O-O 11. Nxe7+ Qxe7 12. O-O-O d6 13. Ne1 Be6 14. Qe2 Nf4 15. Qf1 Qf7 16. b3 a5 17. g3 Ng6 18. Ng2 a4 19. Kb2 axb3 20. cxb3 Ne7 21. f4 Bg4 22. Rd2 Nc6 23. h3 Be6 24. f5 Bd7 25. g4 Ra6 26. g5 Rfa8 27. a4 fxg5 28. Bxg5 h6 29. Be3 Nd4 30. Nh4 Nxb3 31. Rg2 Rxa4 32. Kc3 Nd4 33. Bxh6 Ra3+ 34. Kd2 Ra2+ 35. Ke1 Ra1+ 36. Kf2 R8a2+ 37. Kg1 Rxf1+ 38. Kxf1 Rxg2 39. Nxg2 gxh6 40. Rg1 Qxc4+ 41. Kf2 Qe2+ 42. Kg3 Nf3 43. Nh4 Nxg1 0-1
    """
