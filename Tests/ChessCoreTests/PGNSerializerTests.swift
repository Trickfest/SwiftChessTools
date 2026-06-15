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
    let exported = serializer.pgn(from: game, lineWidth: 120)

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
    let exported = serializer.pgn(from: game)

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
    let exported = serializer.pgn(from: game)

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

    let exported = serializer.pgn(from: original, lineWidth: 32)
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

    for game in games {
        let reparsed = try serializer.game(from: serializer.pgn(from: game))
        #expect(reparsed.mainlineMoves == game.mainlineMoves)
        #expect(reparsed.finalPosition == game.finalPosition)
        #expect(reparsed.result == game.result)
    }
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
