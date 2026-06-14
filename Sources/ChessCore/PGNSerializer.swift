//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation

/// A one-based source location in PGN text.
public struct PGNSourceLocation: Equatable, Sendable, CustomStringConvertible {

    /// One-based line number.
    public let line: Int

    /// One-based column number.
    public let column: Int

    /// Creates a source location.
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    /// Human-readable source location.
    public var description: String {
        "line \(line), column \(column)"
    }

}

/// Context attached to PGN parser and semantic replay failures.
public struct PGNParsingContext: Equatable, Sendable, CustomStringConvertible {

    /// Zero-based game index within a parsed PGN database.
    public let gameIndex: Int?

    /// One-based ply within the game.
    public let ply: Int?

    /// Full-move number associated with the failure.
    public let moveNumber: Int?

    /// Token text associated with the failure, when available.
    public let token: String?

    /// Source location associated with the failure, when available.
    public let location: PGNSourceLocation?

    /// Creates parser context.
    public init(
        gameIndex: Int? = nil,
        ply: Int? = nil,
        moveNumber: Int? = nil,
        token: String? = nil,
        location: PGNSourceLocation? = nil
    ) {
        self.gameIndex = gameIndex
        self.ply = ply
        self.moveNumber = moveNumber
        self.token = token
        self.location = location
    }

    /// Human-readable context.
    public var description: String {
        var parts: [String] = []
        if let gameIndex {
            parts.append("game \(gameIndex + 1)")
        }
        if let moveNumber {
            parts.append("move \(moveNumber)")
        }
        if let ply {
            parts.append("ply \(ply)")
        }
        if let token {
            parts.append("token \(token)")
        }
        if let location {
            parts.append(location.description)
        }
        return parts.isEmpty ? "unknown context" : parts.joined(separator: ", ")
    }

}

/// Errors thrown while parsing Portable Game Notation.
public enum PGNParsingError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case emptyInput
    case expectedSingleGame(actual: Int)
    case unterminatedString(PGNSourceLocation)
    case unterminatedComment(PGNSourceLocation)
    case invalidTag(PGNParsingContext)
    case invalidResultMarker(String, PGNParsingContext)
    case invalidNAG(String, PGNParsingContext)
    case unexpectedToken(String, PGNParsingContext)
    case missingResult(PGNParsingContext)
    case resultMismatch(tag: PGNResult, movetext: PGNResult, PGNParsingContext)
    case invalidSetUpValue(String, PGNParsingContext)
    case missingFEN(PGNParsingContext)
    case fenParsingFailed(String, FENParsingError, PGNParsingContext)
    case sanParsingFailed(String, SANParsingError, PGNParsingContext)
    case resultConflictsWithFinalStatus(result: PGNResult, status: GameStatus, PGNParsingContext)
    case unsupportedRecursiveVariation(PGNParsingContext)

    /// Human-readable error text.
    public var description: String {
        switch self {
        case .emptyInput:
            return "PGN input is empty."
        case let .expectedSingleGame(actual):
            return "Expected one PGN game, found \(actual)."
        case let .unterminatedString(location):
            return "Unterminated PGN string at \(location)."
        case let .unterminatedComment(location):
            return "Unterminated PGN comment at \(location)."
        case let .invalidTag(context):
            return "Invalid PGN tag at \(context)."
        case let .invalidResultMarker(value, context):
            return "Invalid PGN result marker '\(value)' at \(context)."
        case let .invalidNAG(value, context):
            return "Invalid PGN numeric annotation glyph '\(value)' at \(context)."
        case let .unexpectedToken(value, context):
            return "Unexpected PGN token '\(value)' at \(context)."
        case let .missingResult(context):
            return "PGN game is missing a movetext result marker at \(context)."
        case let .resultMismatch(tag, movetext, context):
            return "PGN Result tag \(tag) does not match movetext result \(movetext) at \(context)."
        case let .invalidSetUpValue(value, context):
            return "Invalid PGN SetUp tag value '\(value)' at \(context)."
        case let .missingFEN(context):
            return "PGN SetUp tag requires a FEN tag at \(context)."
        case let .fenParsingFailed(value, error, context):
            return "Invalid PGN FEN '\(value)' at \(context): \(error.description)"
        case let .sanParsingFailed(value, error, context):
            return "Invalid PGN SAN '\(value)' at \(context): \(error.description)"
        case let .resultConflictsWithFinalStatus(result, status, context):
            return "PGN result \(result) conflicts with final status \(status) at \(context)."
        case let .unsupportedRecursiveVariation(context):
            return "PGN recursive annotation variations are not supported yet at \(context)."
        }
    }

    public var errorDescription: String? {
        description
    }
}

/// Errors thrown while building PGN from move lists.
public enum PGNSerializationError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case illegalMove(Move, PGNParsingContext)
    case resultConflictsWithFinalStatus(result: PGNResult, status: GameStatus, PGNParsingContext)

    /// Human-readable error text.
    public var description: String {
        switch self {
        case let .illegalMove(move, context):
            return "Cannot serialize illegal move \(move) at \(context)."
        case let .resultConflictsWithFinalStatus(result, status, context):
            return "Cannot serialize result \(result) because final status is \(status) at \(context)."
        }
    }

    public var errorDescription: String? {
        description
    }
}

/// A PGN tag pair such as `[Event "Casual Game"]`.
public struct PGNTagPair: Equatable, Sendable {

    /// Tag name.
    public let name: String

    /// Tag value without surrounding quotes.
    public let value: String

    /// Creates a tag pair.
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

}

/// A PGN game result.
public enum PGNResult: String, CaseIterable, Equatable, Sendable, CustomStringConvertible {
    case whiteWins = "1-0"
    case blackWins = "0-1"
    case draw = "1/2-1/2"
    case unfinished = "*"

    /// Creates a result from a PGN result marker.
    public init?(marker: String) {
        self.init(rawValue: marker)
    }

    /// PGN result marker.
    public var description: String {
        rawValue
    }
}

/// A PGN numeric annotation glyph.
public struct PGNNumericAnnotationGlyph: RawRepresentable, Hashable, Sendable, CustomStringConvertible {

    /// Numeric annotation value.
    public let rawValue: Int

    /// Creates a NAG value in the PGN-defined 0...255 range.
    public init?(rawValue: Int) {
        guard (0...255).contains(rawValue) else {
            return nil
        }
        self.rawValue = rawValue
    }

    /// PGN NAG spelling such as `$1`.
    public var description: String {
        "$\(rawValue)"
    }

}

/// A semantically validated move from a PGN mainline.
public struct PGNMoveRecord: Equatable, Sendable {

    /// One-based ply in the PGN mainline.
    public let ply: Int

    /// Full-move number for this move.
    public let moveNumber: Int

    /// Side that made this move.
    public let color: PieceColor

    /// Canonical SAN for the move in its pre-move position.
    public let san: String

    /// SAN token as it appeared in the source PGN, after symbolic annotations
    /// such as `!` or `?` were removed.
    public let sourceSAN: String

    /// Concrete move resolved by semantic replay.
    public let move: Move

    /// Comments attached to this move. Lichess clock and eval comments are
    /// preserved as ordinary PGN comments.
    public let comments: [String]

    /// Numeric annotation glyphs attached to this move.
    public let nags: [PGNNumericAnnotationGlyph]

    /// Creates a PGN move record.
    public init(
        ply: Int,
        moveNumber: Int,
        color: PieceColor,
        san: String,
        sourceSAN: String,
        move: Move,
        comments: [String] = [],
        nags: [PGNNumericAnnotationGlyph] = []
    ) {
        self.ply = ply
        self.moveNumber = moveNumber
        self.color = color
        self.san = san
        self.sourceSAN = sourceSAN
        self.move = move
        self.comments = comments
        self.nags = nags
    }

}

/// A parsed and semantically validated PGN game.
public struct PGNGame: Equatable, Sendable {

    /// Tag pairs in source order.
    public let tagPairs: [PGNTagPair]

    /// Starting position, either the standard initial position or the FEN tag
    /// position for setup games.
    public let initialPosition: Position

    /// Validated mainline move records.
    public let moveRecords: [PGNMoveRecord]

    /// Game result from the movetext result marker.
    public let result: PGNResult

    /// Final position after replaying the mainline.
    public let finalPosition: Position

    /// Creates a validated PGN game model.
    public init(
        tagPairs: [PGNTagPair],
        initialPosition: Position,
        moveRecords: [PGNMoveRecord],
        result: PGNResult,
        finalPosition: Position
    ) {
        self.tagPairs = tagPairs
        self.initialPosition = initialPosition
        self.moveRecords = moveRecords
        self.result = result
        self.finalPosition = finalPosition
    }

    /// Mainline moves in order.
    public var mainlineMoves: [Move] {
        moveRecords.map(\.move)
    }

    /// Returns the first value for a tag name, using PGN's case-sensitive tag
    /// names.
    public func tagValue(for name: String) -> String? {
        tagPairs.first { $0.name == name }?.value
    }

}

/// Parses, validates, and exports Portable Game Notation.
public final class PGNSerializer {

    /// Full FEN for the standard starting position.
    public static let standardStartingFEN =
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    private static let standardInitialPosition =
        try! FENSerializer().position(from: PGNSerializer.standardStartingFEN)

    private static let standardTagNames = [
        "Event", "Site", "Date", "Round", "White", "Black", "Result",
    ]

    private let sanSerializer: SANSerializer
    private let fenSerializer: FENSerializer

    /// Creates a PGN serializer.
    public init(
        sanSerializer: SANSerializer = SANSerializer(),
        fenSerializer: FENSerializer = FENSerializer()
    ) {
        self.sanSerializer = sanSerializer
        self.fenSerializer = fenSerializer
    }

    /// Parses exactly one PGN game.
    ///
    /// Parsing is syntax-aware and then semantically validates every SAN move by
    /// replaying it through `Game` and `SANSerializer`.
    public func game(from pgn: String) throws -> PGNGame {
        let games = try self.games(from: pgn)
        guard games.count == 1 else {
            throw PGNParsingError.expectedSingleGame(actual: games.count)
        }
        return games[0]
    }

    /// Parses a PGN database containing one or more games.
    ///
    /// Comments and NAGs are preserved on the nearest preceding move. Recursive
    /// annotation variations are rejected for this first PGN milestone.
    public func games(from pgn: String) throws -> [PGNGame] {
        var lexer = PGNLexer(input: pgn)
        let tokens = try lexer.tokens()
        var parser = PGNSyntaxParser(tokens: tokens)
        let parsedGames = try parser.parseGames()
        return try parsedGames.enumerated().map { gameIndex, parsedGame in
            try self.validatedGame(from: parsedGame, gameIndex: gameIndex)
        }
    }

    /// Builds a PGN game model from standard-position moves.
    public func game(
        moves: [Move],
        tags: [PGNTagPair] = [],
        result: PGNResult = .unfinished
    ) throws -> PGNGame {
        try self.game(
            initialPosition: Self.standardInitialPosition,
            moves: moves,
            tags: tags,
            result: result
        )
    }

    /// Builds a PGN game model from an initial position and concrete moves.
    public func game(
        initialPosition: Position,
        moves: [Move],
        tags: [PGNTagPair] = [],
        result: PGNResult = .unfinished
    ) throws -> PGNGame {
        let game = Game(position: initialPosition)
        var records: [PGNMoveRecord] = []

        for move in moves {
            let ply = records.count + 1
            let context = PGNParsingContext(
                ply: ply,
                moveNumber: game.position.counter.fullMoves,
                token: move.description
            )

            guard game.legalMoves.contains(move) else {
                throw PGNSerializationError.illegalMove(move, context)
            }

            let san = self.sanSerializer.san(for: move, in: game)
            records.append(PGNMoveRecord(
                ply: ply,
                moveNumber: game.position.counter.fullMoves,
                color: game.position.state.turn,
                san: san,
                sourceSAN: san,
                move: move
            ))
            game.apply(move: move)
        }

        try self.validateSerializedResult(result, against: game.status)

        return PGNGame(
            tagPairs: self.tagsWithResult(tags, result: result),
            initialPosition: initialPosition,
            moveRecords: records,
            result: result,
            finalPosition: game.position
        )
    }

    /// Exports a PGN game in deterministic reduced export style, preserving
    /// move comments and NAGs when present.
    public func pgn(from game: PGNGame, lineWidth: Int = 80) -> String {
        let tagLines = self.exportTagPairs(for: game)
            .map { "[\($0.name) \"\(self.escapedTagValue($0.value))\"]" }
        let movetext = self.wrappedMovetext(self.movetextTokens(for: game), lineWidth: lineWidth)
        return (tagLines + ["", movetext]).joined(separator: "\n") + "\n"
    }

    /// Builds and exports standard-position moves as PGN.
    public func pgn(
        moves: [Move],
        tags: [PGNTagPair] = [],
        result: PGNResult = .unfinished,
        lineWidth: Int = 80
    ) throws -> String {
        try self.pgn(
            from: self.game(moves: moves, tags: tags, result: result),
            lineWidth: lineWidth
        )
    }

    /// Builds and exports moves from an explicit initial position as PGN.
    public func pgn(
        initialPosition: Position,
        moves: [Move],
        tags: [PGNTagPair] = [],
        result: PGNResult = .unfinished,
        lineWidth: Int = 80
    ) throws -> String {
        try self.pgn(
            from: self.game(
                initialPosition: initialPosition,
                moves: moves,
                tags: tags,
                result: result
            ),
            lineWidth: lineWidth
        )
    }

    private func validatedGame(from parsedGame: PGNParsedGame, gameIndex: Int) throws -> PGNGame {
        let result = try self.result(from: parsedGame, gameIndex: gameIndex)
        let initialPosition = try self.initialPosition(from: parsedGame, gameIndex: gameIndex)
        let game = Game(position: initialPosition)
        var records: [PGNMoveRecord] = []

        for parsedMove in parsedGame.moves {
            let ply = records.count + 1
            let context = PGNParsingContext(
                gameIndex: gameIndex,
                ply: ply,
                moveNumber: game.position.counter.fullMoves,
                token: parsedMove.san,
                location: parsedMove.location
            )

            let move: Move
            do {
                move = try self.sanSerializer.move(for: parsedMove.san, in: game)
            } catch let error as SANParsingError {
                throw PGNParsingError.sanParsingFailed(parsedMove.san, error, context)
            }

            let canonicalSAN = self.sanSerializer.san(for: move, in: game)
            records.append(PGNMoveRecord(
                ply: ply,
                moveNumber: game.position.counter.fullMoves,
                color: game.position.state.turn,
                san: canonicalSAN,
                sourceSAN: parsedMove.san,
                move: move,
                comments: parsedMove.comments,
                nags: parsedMove.nags
            ))
            game.apply(move: move)
        }

        try self.validateParsedResult(
            result,
            against: game.status,
            context: PGNParsingContext(gameIndex: gameIndex)
        )

        return PGNGame(
            tagPairs: parsedGame.tags,
            initialPosition: initialPosition,
            moveRecords: records,
            result: result,
            finalPosition: game.position
        )
    }

    private func result(from parsedGame: PGNParsedGame, gameIndex: Int) throws -> PGNResult {
        guard let movetextResult = parsedGame.result else {
            throw PGNParsingError.missingResult(PGNParsingContext(gameIndex: gameIndex))
        }

        if let resultTagValue = parsedGame.tagValue(for: "Result") {
            guard let tagResult = PGNResult(marker: resultTagValue) else {
                throw PGNParsingError.invalidResultMarker(
                    resultTagValue,
                    PGNParsingContext(gameIndex: gameIndex, token: resultTagValue)
                )
            }
            guard tagResult == movetextResult else {
                throw PGNParsingError.resultMismatch(
                    tag: tagResult,
                    movetext: movetextResult,
                    PGNParsingContext(gameIndex: gameIndex)
                )
            }
        }

        return movetextResult
    }

    private func validateParsedResult(
        _ result: PGNResult,
        against status: GameStatus,
        context: PGNParsingContext
    ) throws {
        guard let expectedResult = self.expectedPGNResult(for: status) else {
            return
        }
        guard result == expectedResult else {
            throw PGNParsingError.resultConflictsWithFinalStatus(
                result: result,
                status: status,
                context
            )
        }
    }

    private func validateSerializedResult(_ result: PGNResult, against status: GameStatus) throws {
        guard let expectedResult = self.expectedPGNResult(for: status) else {
            return
        }
        guard result == expectedResult else {
            throw PGNSerializationError.resultConflictsWithFinalStatus(
                result: result,
                status: status,
                PGNParsingContext()
            )
        }
    }

    private func expectedPGNResult(for status: GameStatus) -> PGNResult? {
        switch status {
        case .ongoing:
            return nil
        case let .checkmate(winner):
            return winner == .white ? .whiteWins : .blackWins
        case .draw:
            return .draw
        }
    }

    private func initialPosition(from parsedGame: PGNParsedGame, gameIndex: Int) throws -> Position {
        if let setUp = parsedGame.tagValue(for: "SetUp"), setUp != "0", setUp != "1" {
            throw PGNParsingError.invalidSetUpValue(
                setUp,
                PGNParsingContext(gameIndex: gameIndex, token: setUp)
            )
        }

        if parsedGame.tagValue(for: "SetUp") == "1", parsedGame.tagValue(for: "FEN") == nil {
            throw PGNParsingError.missingFEN(PGNParsingContext(gameIndex: gameIndex))
        }

        guard let fen = parsedGame.tagValue(for: "FEN") else {
            return Self.standardInitialPosition
        }

        do {
            return try self.fenSerializer.position(from: fen)
        } catch let error as FENParsingError {
            throw PGNParsingError.fenParsingFailed(
                fen,
                error,
                PGNParsingContext(gameIndex: gameIndex, token: fen)
            )
        }
    }

    private func tagsWithResult(_ tags: [PGNTagPair], result: PGNResult) -> [PGNTagPair] {
        tags.filter { $0.name != "Result" } + [PGNTagPair(name: "Result", value: result.rawValue)]
    }

    private func exportTagPairs(for game: PGNGame) -> [PGNTagPair] {
        let defaults = [
            "Event": "?",
            "Site": "?",
            "Date": "????.??.??",
            "Round": "?",
            "White": "?",
            "Black": "?",
            "Result": game.result.rawValue,
        ]

        let standardTags = Self.standardTagNames.map { name in
            if name == "Result" {
                return PGNTagPair(name: name, value: game.result.rawValue)
            }
            return PGNTagPair(name: name, value: game.tagValue(for: name) ?? defaults[name]!)
        }

        var tags = standardTags
        if self.fenSerializer.fen(from: game.initialPosition) != Self.standardStartingFEN {
            tags.append(PGNTagPair(name: "SetUp", value: "1"))
            tags.append(PGNTagPair(name: "FEN", value: self.fenSerializer.fen(from: game.initialPosition)))
        }

        let skippedNames = Set(Self.standardTagNames + ["SetUp", "FEN"])
        tags += game.tagPairs.filter { !skippedNames.contains($0.name) }
        return tags
    }

    private func escapedTagValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func movetextTokens(for game: PGNGame) -> [String] {
        var tokens: [String] = []
        var previousColor: PieceColor?

        for record in game.moveRecords {
            if record.color == .white {
                tokens.append("\(record.moveNumber).")
            } else if previousColor != .white {
                tokens.append("\(record.moveNumber)...")
            }

            tokens.append(record.san)
            tokens += record.nags.map(\.description)
            tokens += record.comments.map { "{ \(self.sanitizedComment($0)) }" }
            previousColor = record.color
        }

        tokens.append(game.result.rawValue)
        return tokens
    }

    private func sanitizedComment(_ comment: String) -> String {
        comment.replacingOccurrences(of: "}", with: "")
    }

    private func wrappedMovetext(_ tokens: [String], lineWidth: Int) -> String {
        guard lineWidth > 0 else {
            return tokens.joined(separator: " ")
        }

        var lines: [String] = []
        var currentLine = ""

        for token in tokens {
            if currentLine.isEmpty {
                currentLine = token
            } else if currentLine.count + 1 + token.count > lineWidth {
                lines.append(currentLine)
                currentLine = token
            } else {
                currentLine += " " + token
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.joined(separator: "\n")
    }

}

private struct PGNParsedGame: Equatable {
    var tags: [PGNTagPair]
    var moves: [PGNParsedMove]
    var result: PGNResult?

    func tagValue(for name: String) -> String? {
        tags.first { $0.name == name }?.value
    }
}

private struct PGNParsedMove: Equatable {
    var san: String
    var comments: [String]
    var nags: [PGNNumericAnnotationGlyph]
    var location: PGNSourceLocation
}

private struct PGNToken: Equatable {
    enum Kind: Equatable {
        case leftBracket
        case rightBracket
        case leftParenthesis
        case rightParenthesis
        case dot
        case string(String)
        case symbol(String)
        case comment(String)
        case nag(PGNNumericAnnotationGlyph)
    }

    var kind: Kind
    var location: PGNSourceLocation

    var text: String {
        switch kind {
        case .leftBracket:
            return "["
        case .rightBracket:
            return "]"
        case .leftParenthesis:
            return "("
        case .rightParenthesis:
            return ")"
        case .dot:
            return "."
        case let .string(value):
            return "\"\(value)\""
        case let .symbol(value):
            return value
        case let .comment(value):
            return "{\(value)}"
        case let .nag(value):
            return value.description
        }
    }
}

private struct PGNLexer {
    let input: String
    private var index: String.Index
    private var line = 1
    private var column = 1

    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }

    mutating func tokens() throws -> [PGNToken] {
        var tokens: [PGNToken] = []

        while !self.isAtEnd {
            let character = self.currentCharacter

            if character == "\u{FEFF}", self.line == 1, self.column == 1 {
                self.advance()
            } else if character == "%", self.column == 1 {
                self.skipLine()
            } else if character.isWhitespace {
                self.advance()
            } else {
                let location = self.location
                switch character {
                case "[":
                    self.advance()
                    tokens.append(PGNToken(kind: .leftBracket, location: location))
                case "]":
                    self.advance()
                    tokens.append(PGNToken(kind: .rightBracket, location: location))
                case "(":
                    self.advance()
                    tokens.append(PGNToken(kind: .leftParenthesis, location: location))
                case ")":
                    self.advance()
                    tokens.append(PGNToken(kind: .rightParenthesis, location: location))
                case ".":
                    self.advance()
                    tokens.append(PGNToken(kind: .dot, location: location))
                case "\"":
                    tokens.append(PGNToken(
                        kind: .string(try self.readString(startingAt: location)),
                        location: location
                    ))
                case "{":
                    tokens.append(PGNToken(
                        kind: .comment(try self.readBraceComment(startingAt: location)),
                        location: location
                    ))
                case ";":
                    tokens.append(PGNToken(
                        kind: .comment(self.readLineComment()),
                        location: location
                    ))
                case "$":
                    tokens.append(PGNToken(
                        kind: .nag(try self.readNAG(startingAt: location)),
                        location: location
                    ))
                default:
                    tokens.append(PGNToken(
                        kind: .symbol(self.readSymbol()),
                        location: location
                    ))
                }
            }
        }

        return tokens
    }

    private var isAtEnd: Bool {
        index == input.endIndex
    }

    private var currentCharacter: Character {
        input[index]
    }

    private var location: PGNSourceLocation {
        PGNSourceLocation(line: line, column: column)
    }

    private mutating func advance() {
        let character = input[index]
        index = input.index(after: index)
        if character == "\n" || character == "\r" {
            line += 1
            column = 1
        } else {
            column += 1
        }
    }

    private mutating func skipLine() {
        while !isAtEnd, currentCharacter != "\n", currentCharacter != "\r" {
            self.advance()
        }
    }

    private mutating func readString(startingAt location: PGNSourceLocation) throws -> String {
        self.advance()
        var value = ""

        while !isAtEnd {
            let character = currentCharacter
            if character == "\"" {
                self.advance()
                return value
            }
            if character == "\\" {
                self.advance()
                guard !isAtEnd else {
                    throw PGNParsingError.unterminatedString(location)
                }
                value.append(currentCharacter)
                self.advance()
            } else {
                value.append(character)
                self.advance()
            }
        }

        throw PGNParsingError.unterminatedString(location)
    }

    private mutating func readBraceComment(startingAt location: PGNSourceLocation) throws -> String {
        self.advance()
        var value = ""

        while !isAtEnd {
            let character = currentCharacter
            if character == "}" {
                self.advance()
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            value.append(character)
            self.advance()
        }

        throw PGNParsingError.unterminatedComment(location)
    }

    private mutating func readLineComment() -> String {
        self.advance()
        var value = ""

        while !isAtEnd, currentCharacter != "\n", currentCharacter != "\r" {
            value.append(currentCharacter)
            self.advance()
        }

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private mutating func readNAG(startingAt location: PGNSourceLocation) throws -> PGNNumericAnnotationGlyph {
        self.advance()
        var digits = ""

        while !isAtEnd, currentCharacter.isNumber {
            digits.append(currentCharacter)
            self.advance()
        }

        guard let value = Int(digits), let nag = PGNNumericAnnotationGlyph(rawValue: value) else {
            throw PGNParsingError.invalidNAG(
                "$\(digits)",
                PGNParsingContext(location: location)
            )
        }

        return nag
    }

    private mutating func readSymbol() -> String {
        var value = ""

        while !isAtEnd, !self.isSymbolDelimiter(currentCharacter) {
            value.append(currentCharacter)
            self.advance()
        }

        return value
    }

    private func isSymbolDelimiter(_ character: Character) -> Bool {
        character.isWhitespace
            || character == "["
            || character == "]"
            || character == "("
            || character == ")"
            || character == "{"
            || character == "}"
            || character == "\""
            || character == ";"
            || character == "$"
            || character == "."
    }
}

private struct PGNSyntaxParser {
    private let tokens: [PGNToken]
    private var index = 0

    init(tokens: [PGNToken]) {
        self.tokens = tokens
    }

    mutating func parseGames() throws -> [PGNParsedGame] {
        var games: [PGNParsedGame] = []
        self.skipLooseComments()

        while !self.isAtEnd {
            let tags = try self.parseTags(gameIndex: games.count)
            let parsedGame = try self.parseMovetext(tags: tags, gameIndex: games.count)
            games.append(parsedGame)
            self.skipLooseComments()
        }

        guard !games.isEmpty else {
            throw PGNParsingError.emptyInput
        }

        return games
    }

    private var isAtEnd: Bool {
        index >= tokens.count
    }

    private var currentToken: PGNToken {
        tokens[index]
    }

    private mutating func advance() -> PGNToken {
        let token = tokens[index]
        index += 1
        return token
    }

    private mutating func skipLooseComments() {
        while !isAtEnd {
            if case .comment = currentToken.kind {
                _ = self.advance()
            } else {
                break
            }
        }
    }

    private mutating func parseTags(gameIndex: Int) throws -> [PGNTagPair] {
        var tags: [PGNTagPair] = []

        while !isAtEnd {
            guard case .leftBracket = currentToken.kind else {
                break
            }
            let location = self.advance().location
            let context = PGNParsingContext(gameIndex: gameIndex, location: location)

            guard !isAtEnd,
                  case let .symbol(parsedName) = currentToken.kind,
                  self.isValidTagName(parsedName)
            else {
                throw PGNParsingError.invalidTag(context)
            }
            let name = self.advance().text

            guard !isAtEnd, case let .string(value) = currentToken.kind else {
                throw PGNParsingError.invalidTag(context)
            }
            _ = self.advance()

            guard !isAtEnd, case .rightBracket = currentToken.kind else {
                throw PGNParsingError.invalidTag(context)
            }
            _ = self.advance()

            tags.append(PGNTagPair(name: name, value: value))
        }

        return tags
    }

    private func isValidTagName(_ name: String) -> Bool {
        guard let first = name.first, first.isLetter else {
            return false
        }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }

    private mutating func parseMovetext(tags: [PGNTagPair], gameIndex: Int) throws -> PGNParsedGame {
        var moves: [PGNParsedMove] = []

        while !isAtEnd {
            let token = currentToken

            switch token.kind {
            case .leftBracket:
                throw PGNParsingError.missingResult(PGNParsingContext(
                    gameIndex: gameIndex,
                    location: token.location
                ))
            case .rightBracket, .string:
                throw PGNParsingError.unexpectedToken(
                    token.text,
                    PGNParsingContext(gameIndex: gameIndex, token: token.text, location: token.location)
                )
            case .leftParenthesis:
                throw PGNParsingError.unsupportedRecursiveVariation(PGNParsingContext(
                    gameIndex: gameIndex,
                    location: token.location
                ))
            case .rightParenthesis:
                throw PGNParsingError.unexpectedToken(
                    token.text,
                    PGNParsingContext(gameIndex: gameIndex, token: token.text, location: token.location)
                )
            case .dot:
                _ = self.advance()
            case let .comment(comment):
                _ = self.advance()
                if !moves.isEmpty {
                    moves[moves.count - 1].comments.append(comment)
                }
            case let .nag(nag):
                _ = self.advance()
                guard !moves.isEmpty else {
                    throw PGNParsingError.unexpectedToken(
                        nag.description,
                        PGNParsingContext(
                            gameIndex: gameIndex,
                            token: nag.description,
                            location: token.location
                        )
                    )
                }
                moves[moves.count - 1].nags.append(nag)
            case let .symbol(symbol):
                if self.isMoveNumberIndicator(at: index) {
                    self.skipMoveNumberIndicator()
                } else if let result = PGNResult(marker: symbol) {
                    _ = self.advance()
                    return PGNParsedGame(tags: tags, moves: moves, result: result)
                } else {
                    let parsedSAN = self.sanAndSuffixNAGs(from: symbol)
                    _ = self.advance()
                    moves.append(PGNParsedMove(
                        san: parsedSAN.san,
                        comments: [],
                        nags: parsedSAN.nags,
                        location: token.location
                    ))
                }
            }
        }

        throw PGNParsingError.missingResult(PGNParsingContext(gameIndex: gameIndex))
    }

    private func isMoveNumberIndicator(at tokenIndex: Int) -> Bool {
        guard tokenIndex < tokens.count,
              case let .symbol(value) = tokens[tokenIndex].kind,
              !value.isEmpty,
              value.allSatisfy(\.isNumber)
        else {
            return false
        }

        let nextIndex = tokenIndex + 1
        guard nextIndex < tokens.count, case .dot = tokens[nextIndex].kind else {
            return false
        }
        return true
    }

    private mutating func skipMoveNumberIndicator() {
        _ = self.advance()
        while !isAtEnd {
            if case .dot = currentToken.kind {
                _ = self.advance()
            } else {
                break
            }
        }
    }

    private func sanAndSuffixNAGs(from symbol: String) -> (san: String, nags: [PGNNumericAnnotationGlyph]) {
        var san = symbol
        var nags: [PGNNumericAnnotationGlyph] = []
        let suffixes: [(String, Int)] = [
            ("!!", 3),
            ("??", 4),
            ("!?", 5),
            ("?!", 6),
            ("!", 1),
            ("?", 2),
        ]

        var consumedSuffix = true
        while consumedSuffix {
            consumedSuffix = false
            for (suffix, nagValue) in suffixes where san.hasSuffix(suffix) {
                san.removeLast(suffix.count)
                if let nag = PGNNumericAnnotationGlyph(rawValue: nagValue) {
                    nags.append(nag)
                }
                consumedSuffix = true
                break
            }
        }

        return (san, nags)
    }

}
