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

import ChessCore
import Foundation

/// Parsed representation of one line emitted by a UCI engine.
///
/// `ChessUCI` parses text into values, but it does not own an engine process,
/// choose moves, or mutate game state.
public enum UCIParsedLine: Equatable, Sendable {
    /// Engine identification such as `id name` or `id author`.
    case id(UCIIdentification)

    /// Engine option declaration.
    case option(UCIOption)

    /// UCI handshake completion marker.
    case uciOK

    /// Engine readiness marker.
    case readyOK

    /// Copy-protection status reported by an engine.
    case copyProtection(UCICopyProtectionStatus)

    /// Registration status reported by an engine.
    case registration(UCIRegistrationStatus)

    /// An `info` line containing search metadata, score data, or a principal variation.
    case info(UCIInfoLine)

    /// A `bestmove` line returned when a search finishes.
    case bestMove(UCIBestMove)

    /// A line that `ChessUCI` intentionally leaves uninterpreted.
    case unknown(String)
}

/// Parsed engine identification output.
public struct UCIIdentification: Equatable, Sendable {
    /// Original engine output.
    public let rawLine: String

    /// Identification field kind.
    public let kind: UCIIdentificationKind

    /// Identification value.
    public let value: String

    /// Creates parsed engine identification output.
    public init(rawLine: String, kind: UCIIdentificationKind, value: String) {
        self.rawLine = rawLine
        self.kind = kind
        self.value = value
    }
}

/// UCI engine identification field.
public enum UCIIdentificationKind: Equatable, Sendable {
    /// Engine name.
    case name

    /// Engine author.
    case author
}

/// Parsed UCI engine option declaration.
public struct UCIOption: Equatable, Sendable {
    /// Original engine output.
    public let rawLine: String

    /// Option name.
    public let name: String

    /// Option type.
    public let type: UCIOptionType

    /// Default value text, when supplied.
    public let defaultValue: String?

    /// Minimum integer value for spin options.
    public let min: Int?

    /// Maximum integer value for spin options.
    public let max: Int?

    /// Enumerated values for combo options.
    public let vars: [String]

    /// Creates parsed engine option output.
    public init(
        rawLine: String,
        name: String,
        type: UCIOptionType,
        defaultValue: String? = nil,
        min: Int? = nil,
        max: Int? = nil,
        vars: [String] = []
    ) {
        self.rawLine = rawLine
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.min = min
        self.max = max
        self.vars = vars
    }
}

/// UCI engine option type.
public enum UCIOptionType: Equatable, Sendable {
    /// Boolean option.
    case check

    /// Integer range option.
    case spin

    /// Enumerated string option.
    case combo

    /// Button/action option.
    case button

    /// Free-form string option.
    case string

    /// Option type text that `ChessUCI` does not recognize.
    case unknown(String)
}

/// UCI copy-protection status.
public enum UCICopyProtectionStatus: Equatable, Sendable {
    /// The engine is checking copy-protection state.
    case checking

    /// Copy-protection check succeeded.
    case ok

    /// Copy-protection check failed.
    case error

    /// Status text that `ChessUCI` does not recognize.
    case unknown(String)
}

/// UCI registration status.
public enum UCIRegistrationStatus: Equatable, Sendable {
    /// The engine is checking registration state.
    case checking

    /// Registration check succeeded.
    case ok

    /// Registration check failed.
    case error

    /// Status text that `ChessUCI` does not recognize.
    case unknown(String)
}

/// Parsed `bestmove` output from a UCI engine.
public struct UCIBestMove: Equatable, Sendable {
    /// Original engine output.
    public let rawLine: String

    /// Best move reported by the engine, or `nil` for `(none)`, `0000`, or invalid move text.
    public let move: Move?

    /// Optional ponder move reported after the best move.
    public let ponder: Move?

    /// Creates parsed best-move output.
    public init(rawLine: String, move: Move?, ponder: Move? = nil) {
        self.rawLine = rawLine
        self.move = move
        self.ponder = ponder
    }
}

/// Parsed `info` output from a UCI engine.
public struct UCIInfoLine: Equatable, Sendable {
    /// Original engine output.
    public let rawLine: String

    /// Search depth in plies.
    public let depth: Int?

    /// Selective search depth in plies.
    public let selectiveDepth: Int?

    /// Elapsed search time in milliseconds.
    public let timeMilliseconds: Int?

    /// Nodes searched.
    public let nodes: Int?

    /// Nodes searched per second.
    public let nodesPerSecond: Int?

    /// Hash table fullness in per mille.
    public let hashfull: Int?

    /// One-based MultiPV line number.
    public let multipv: Int?

    /// Search score from the engine's side-to-move perspective.
    public let score: UCIScore?

    /// Bound marker attached to `score`.
    public let scoreBound: UCIScoreBound

    /// Current move being searched, when reported.
    public let currentMove: Move?

    /// One-based current move number being searched, when reported.
    public let currentMoveNumber: Int?

    /// Principal variation move sequence.
    public let principalVariation: [Move]

    /// Refutation line move sequence.
    public let refutation: [Move]

    /// Current search line, optionally associated with a CPU number.
    public let currentLine: UCICurrentLine?

    /// Tablebase hits.
    public let tablebaseHits: Int?

    /// Shredderbase hits.
    public let shredderbaseHits: Int?

    /// CPU load in per mille.
    public let cpuLoad: Int?

    /// Engine-supplied free-form string from an `info string` line.
    public let string: String?

    /// Creates parsed info output.
    public init(
        rawLine: String,
        depth: Int? = nil,
        selectiveDepth: Int? = nil,
        timeMilliseconds: Int? = nil,
        nodes: Int? = nil,
        nodesPerSecond: Int? = nil,
        hashfull: Int? = nil,
        multipv: Int? = nil,
        score: UCIScore? = nil,
        scoreBound: UCIScoreBound = .exact,
        currentMove: Move? = nil,
        currentMoveNumber: Int? = nil,
        principalVariation: [Move] = [],
        refutation: [Move] = [],
        currentLine: UCICurrentLine? = nil,
        tablebaseHits: Int? = nil,
        shredderbaseHits: Int? = nil,
        cpuLoad: Int? = nil,
        string: String? = nil
    ) {
        self.rawLine = rawLine
        self.depth = depth
        self.selectiveDepth = selectiveDepth
        self.timeMilliseconds = timeMilliseconds
        self.nodes = nodes
        self.nodesPerSecond = nodesPerSecond
        self.hashfull = hashfull
        self.multipv = multipv
        self.score = score
        self.scoreBound = scoreBound
        self.currentMove = currentMove
        self.currentMoveNumber = currentMoveNumber
        self.principalVariation = principalVariation
        self.refutation = refutation
        self.currentLine = currentLine
        self.tablebaseHits = tablebaseHits
        self.shredderbaseHits = shredderbaseHits
        self.cpuLoad = cpuLoad
        self.string = string
    }

    /// Converts the parsed score to a White-positive value for UI display.
    ///
    /// UCI scores are from the side-to-move perspective for the searched
    /// position. ChessUI evaluation display expects positive scores to favor
    /// White, so apps can call this before mapping to a UI-specific type.
    public func whiteRelativeScore(sideToMove: PieceColor) -> UCIWhiteScore? {
        score?.whiteRelative(sideToMove: sideToMove)
    }
}

/// Parsed `info currline` output.
public struct UCICurrentLine: Equatable, Sendable {
    /// Optional CPU number reported before the move sequence.
    public let cpuNumber: Int?

    /// Current line move sequence.
    public let moves: [Move]

    /// Creates parsed current-line output.
    public init(cpuNumber: Int? = nil, moves: [Move]) {
        self.cpuNumber = cpuNumber
        self.moves = moves
    }
}

/// Numeric or mate score reported in a UCI `info score` field.
public enum UCIScore: Equatable, Sendable {
    /// Centipawn score from the side-to-move perspective.
    case centipawns(Int)

    /// Mate score from the side-to-move perspective.
    ///
    /// Positive values mean the side to move can mate; negative values mean
    /// the side to move is getting mated.
    case mate(Int)

    /// Converts the raw UCI score into a White-positive score.
    public func whiteRelative(sideToMove: PieceColor) -> UCIWhiteScore {
        switch self {
        case .centipawns(let centipawns):
            return .centipawns(sideToMove == .white ? centipawns : -centipawns)

        case .mate(let moves):
            let matingSide = moves >= 0 ? sideToMove : sideToMove.opposite
            return .mate(moves: abs(moves), side: matingSide)
        }
    }
}

/// Bound marker attached to a parsed UCI score.
public enum UCIScoreBound: Equatable, Sendable {
    /// Exact score.
    case exact

    /// Lower-bound score.
    case lowerbound

    /// Upper-bound score.
    case upperbound
}

/// Score normalized so positive centipawns favor White.
public enum UCIWhiteScore: Equatable, Sendable {
    /// Centipawn score where positive values favor White.
    case centipawns(Int)

    /// Forced mate for the supplied side.
    case mate(moves: Int, side: PieceColor)
}

/// Stateless parser for common UCI engine output lines.
public struct UCIParser: Sendable {
    /// Creates a parser.
    public init() {}

    /// Parses one complete line of UCI engine output.
    public func parse(_ line: String) -> UCIParsedLine {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = trimmedLine.split { $0 == " " || $0 == "\t" }

        guard let command = tokens.first else {
            return .unknown(line)
        }

        switch command {
        case "id":
            return parseIdentification(rawLine: line, tokens: tokens)
        case "option":
            return .option(parseOption(rawLine: line, tokens: tokens))
        case "uciok":
            return .uciOK
        case "readyok":
            return .readyOK
        case "copyprotection":
            return .copyProtection(parseCopyProtectionStatus(tokens: tokens))
        case "registration":
            return .registration(parseRegistrationStatus(tokens: tokens))
        case "bestmove":
            return .bestMove(parseBestMove(rawLine: line, tokens: tokens))
        case "info":
            return .info(parseInfo(rawLine: line, tokens: tokens))
        default:
            return .unknown(line)
        }
    }

    private func parseIdentification(rawLine: String, tokens: [Substring]) -> UCIParsedLine {
        guard tokens.indices.contains(1) else {
            return .unknown(rawLine)
        }

        let value = tokens.dropFirst(2).joined(separator: " ")
        switch tokens[1] {
        case "name":
            return .id(UCIIdentification(rawLine: rawLine, kind: .name, value: value))
        case "author":
            return .id(UCIIdentification(rawLine: rawLine, kind: .author, value: value))
        default:
            return .unknown(rawLine)
        }
    }

    private func parseOption(rawLine: String, tokens: [Substring]) -> UCIOption {
        let delimiters: Set<String> = ["name", "type", "default", "min", "max", "var"]
        var name = ""
        var type = UCIOptionType.unknown("")
        var defaultValue: String?
        var min: Int?
        var max: Int?
        var vars: [String] = []

        var index = tokens.index(after: tokens.startIndex)
        while tokens.indices.contains(index) {
            switch tokens[index] {
            case "name":
                index = tokens.index(after: index)
                name = readText(tokens, at: &index, until: delimiters) ?? ""
            case "type":
                if tokens.indices.contains(index + 1) {
                    type = optionType(from: tokens[index + 1])
                }
                index = tokens.index(index, offsetBy: 2, limitedBy: tokens.endIndex) ?? tokens.endIndex
            case "default":
                index = tokens.index(after: index)
                defaultValue = readText(tokens, at: &index, until: delimiters)
            case "min":
                readInteger(tokens, at: &index, into: &min)
            case "max":
                readInteger(tokens, at: &index, into: &max)
            case "var":
                index = tokens.index(after: index)
                if let value = readText(tokens, at: &index, until: delimiters) {
                    vars.append(value)
                }
            default:
                index = tokens.index(after: index)
            }
        }

        return UCIOption(
            rawLine: rawLine,
            name: name,
            type: type,
            defaultValue: defaultValue,
            min: min,
            max: max,
            vars: vars
        )
    }

    private func optionType(from token: Substring) -> UCIOptionType {
        switch token {
        case "check":
            return .check
        case "spin":
            return .spin
        case "combo":
            return .combo
        case "button":
            return .button
        case "string":
            return .string
        default:
            return .unknown(String(token))
        }
    }

    private func parseCopyProtectionStatus(tokens: [Substring]) -> UCICopyProtectionStatus {
        guard tokens.indices.contains(1) else {
            return .unknown("")
        }

        switch tokens[1] {
        case "checking":
            return .checking
        case "ok":
            return .ok
        case "error":
            return .error
        default:
            return .unknown(tokens.dropFirst().joined(separator: " "))
        }
    }

    private func parseRegistrationStatus(tokens: [Substring]) -> UCIRegistrationStatus {
        guard tokens.indices.contains(1) else {
            return .unknown("")
        }

        switch tokens[1] {
        case "checking":
            return .checking
        case "ok":
            return .ok
        case "error":
            return .error
        default:
            return .unknown(tokens.dropFirst().joined(separator: " "))
        }
    }

    private func parseBestMove(rawLine: String, tokens: [Substring]) -> UCIBestMove {
        let move = tokens.dropFirst().first.flatMap(parseMoveToken)
        let ponder = tokens.enumerated()
            .first { $0.element == "ponder" }
            .flatMap { index, _ in
                tokens.indices.contains(index + 1) ? parseMoveToken(tokens[index + 1]) : nil
            }

        return UCIBestMove(rawLine: rawLine, move: move, ponder: ponder)
    }

    private func parseInfo(rawLine: String, tokens: [Substring]) -> UCIInfoLine {
        var depth: Int?
        var selectiveDepth: Int?
        var timeMilliseconds: Int?
        var nodes: Int?
        var nodesPerSecond: Int?
        var hashfull: Int?
        var multipv: Int?
        var score: UCIScore?
        var scoreBound = UCIScoreBound.exact
        var currentMove: Move?
        var currentMoveNumber: Int?
        var principalVariation: [Move] = []
        var refutation: [Move] = []
        var currentLine: UCICurrentLine?
        var tablebaseHits: Int?
        var shredderbaseHits: Int?
        var cpuLoad: Int?
        var string: String?

        var index = tokens.index(after: tokens.startIndex)
        while tokens.indices.contains(index) {
            switch tokens[index] {
            case "depth":
                readInteger(tokens, at: &index, into: &depth)
            case "seldepth":
                readInteger(tokens, at: &index, into: &selectiveDepth)
            case "time":
                readInteger(tokens, at: &index, into: &timeMilliseconds)
            case "nodes":
                readInteger(tokens, at: &index, into: &nodes)
            case "nps":
                readInteger(tokens, at: &index, into: &nodesPerSecond)
            case "hashfull":
                readInteger(tokens, at: &index, into: &hashfull)
            case "tbhits":
                readInteger(tokens, at: &index, into: &tablebaseHits)
            case "sbhits":
                readInteger(tokens, at: &index, into: &shredderbaseHits)
            case "cpuload":
                readInteger(tokens, at: &index, into: &cpuLoad)
            case "multipv":
                readInteger(tokens, at: &index, into: &multipv)
            case "currmove":
                currentMove = readMove(tokens, at: &index)
            case "currmovenumber":
                readInteger(tokens, at: &index, into: &currentMoveNumber)
            case "score":
                (score, scoreBound) = readScore(tokens, at: &index)
            case "pv":
                principalVariation = readMovesToEnd(tokens, after: index)
                index = tokens.endIndex
            case "refutation":
                refutation = readMovesToEnd(tokens, after: index)
                index = tokens.endIndex
            case "currline":
                currentLine = readCurrentLine(tokens, at: &index)
            case "string":
                let stringTokens = tokens[tokens.index(after: index)...]
                string = stringTokens.isEmpty ? nil : stringTokens.joined(separator: " ")
                index = tokens.endIndex
            default:
                index = tokens.index(after: index)
            }
        }

        return UCIInfoLine(
            rawLine: rawLine,
            depth: depth,
            selectiveDepth: selectiveDepth,
            timeMilliseconds: timeMilliseconds,
            nodes: nodes,
            nodesPerSecond: nodesPerSecond,
            hashfull: hashfull,
            multipv: multipv,
            score: score,
            scoreBound: scoreBound,
            currentMove: currentMove,
            currentMoveNumber: currentMoveNumber,
            principalVariation: principalVariation,
            refutation: refutation,
            currentLine: currentLine,
            tablebaseHits: tablebaseHits,
            shredderbaseHits: shredderbaseHits,
            cpuLoad: cpuLoad,
            string: string
        )
    }

    private func readInteger(_ tokens: [Substring], at index: inout Int, into value: inout Int?) {
        defer {
            index = tokens.index(index, offsetBy: 2, limitedBy: tokens.endIndex) ?? tokens.endIndex
        }

        guard tokens.indices.contains(index + 1) else { return }
        value = Int(tokens[index + 1])
    }

    private func readMove(_ tokens: [Substring], at index: inout Int) -> Move? {
        defer {
            index = tokens.index(index, offsetBy: 2, limitedBy: tokens.endIndex) ?? tokens.endIndex
        }

        guard tokens.indices.contains(index + 1) else { return nil }
        return parseMoveToken(tokens[index + 1])
    }

    private func readScore(_ tokens: [Substring], at index: inout Int) -> (UCIScore?, UCIScoreBound) {
        defer {
            index = tokens.index(index, offsetBy: 3, limitedBy: tokens.endIndex) ?? tokens.endIndex

            if tokens.indices.contains(index), tokens[index] == "lowerbound" || tokens[index] == "upperbound" {
                index = tokens.index(after: index)
            }
        }

        guard tokens.indices.contains(index + 2),
              let value = Int(tokens[index + 2])
        else {
            return (nil, .exact)
        }

        let score: UCIScore?
        switch tokens[index + 1] {
        case "cp":
            score = .centipawns(value)
        case "mate":
            score = .mate(value)
        default:
            score = nil
        }

        let boundIndex = index + 3
        let bound: UCIScoreBound
        if tokens.indices.contains(boundIndex), tokens[boundIndex] == "lowerbound" {
            bound = .lowerbound
        } else if tokens.indices.contains(boundIndex), tokens[boundIndex] == "upperbound" {
            bound = .upperbound
        } else {
            bound = .exact
        }

        return (score, bound)
    }

    private func readCurrentLine(_ tokens: [Substring], at index: inout Int) -> UCICurrentLine {
        defer {
            index = tokens.endIndex
        }

        var moveStartIndex = tokens.index(after: index)
        var cpuNumber: Int?

        if tokens.indices.contains(moveStartIndex), let parsedCPUNumber = Int(tokens[moveStartIndex]) {
            cpuNumber = parsedCPUNumber
            moveStartIndex = tokens.index(after: moveStartIndex)
        }

        let moves: [Move]
        if tokens.indices.contains(moveStartIndex) {
            moves = tokens[moveStartIndex...].compactMap(parseMoveToken)
        } else {
            moves = []
        }

        return UCICurrentLine(cpuNumber: cpuNumber, moves: moves)
    }

    private func readText(_ tokens: [Substring], at index: inout Int, until delimiters: Set<String>) -> String? {
        var textTokens: [String] = []

        while tokens.indices.contains(index), !delimiters.contains(String(tokens[index])) {
            textTokens.append(String(tokens[index]))
            index = tokens.index(after: index)
        }

        guard !textTokens.isEmpty else { return nil }
        return textTokens.joined(separator: " ")
    }

    private func readMovesToEnd(_ tokens: [Substring], after index: Int) -> [Move] {
        let startIndex = tokens.index(after: index)
        guard tokens.indices.contains(startIndex) else { return [] }
        return tokens[startIndex...].compactMap(parseMoveToken)
    }

    private func parseMoveToken(_ token: Substring) -> Move? {
        guard token != "(none)", token != "0000" else { return nil }
        return try? Move(string: String(token))
    }
}
