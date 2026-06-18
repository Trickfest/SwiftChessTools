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

/// A single command line that can be sent to a UCI-compatible chess engine.
///
/// `UCICommand` formats text, but it does not send the text, wait for engine
/// readiness, own a process, or decide search policy.
public struct UCICommand: CustomStringConvertible, Equatable, Sendable {
    /// Exact command text to send to the engine.
    public let rawValue: String

    /// Creates a command from already formatted UCI text.
    ///
    /// Use this for engine-specific commands that do not have a typed helper.
    /// The value should be one complete UCI command line without a trailing
    /// newline.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Exact command text to send to the engine.
    public var string: String {
        rawValue
    }

    /// Exact command text to send to the engine.
    public var description: String {
        rawValue
    }

    /// Starts the UCI handshake.
    public static let uci = UCICommand(rawValue: "uci")

    /// Asks the engine whether it is ready for another command.
    public static let isReady = UCICommand(rawValue: "isready")

    /// Tells the engine a new game is beginning.
    public static let newGame = UCICommand(rawValue: "ucinewgame")

    /// Stops the current search.
    public static let stop = UCICommand(rawValue: "stop")

    /// Tells the engine that its ponder move occurred.
    public static let ponderHit = UCICommand(rawValue: "ponderhit")

    /// Asks the engine process to quit.
    public static let quit = UCICommand(rawValue: "quit")

    /// Enables or disables UCI debug output.
    public static func debug(_ isEnabled: Bool) -> UCICommand {
        UCICommand(rawValue: "debug \(isEnabled ? "on" : "off")")
    }

    /// Defers engine registration.
    public static let registerLater = UCICommand(rawValue: "register later")

    /// Formats a `register` command with user registration data.
    ///
    /// Name and code are free-form command text. This helper preserves spaces
    /// and does not quote or escape values.
    public static func register(name: String, code: String) -> UCICommand {
        UCICommand(rawValue: "register name \(name) code \(code)")
    }

    /// Formats a `setoption` command.
    ///
    /// UCI option names and values are free-form command text. This helper
    /// preserves spaces and does not quote or escape values.
    public static func setOption(name: String, value: String? = nil) -> UCICommand {
        var command = "setoption name \(name)"

        if let value {
            command += " value \(value)"
        }

        return UCICommand(rawValue: command)
    }

    /// Formats a Boolean `setoption` command using UCI's lowercase spellings.
    public static func setOption(name: String, value: Bool) -> UCICommand {
        setOption(name: name, value: value ? "true" : "false")
    }

    /// Formats an integer `setoption` command.
    public static func setOption(name: String, value: Int) -> UCICommand {
        setOption(name: name, value: String(value))
    }

    /// Formats a `position` command.
    public static func position(_ position: UCIPosition, moves: [Move] = []) -> UCICommand {
        var command = "position \(position.commandText)"

        if !moves.isEmpty {
            command += " moves \(moves.uciCommandText)"
        }

        return UCICommand(rawValue: command)
    }

    /// Formats a `go` command from search options.
    public static func go(_ options: UCIGoOptions) -> UCICommand {
        var parts = ["go"]

        if !options.searchMoves.isEmpty {
            parts.append("searchmoves")
            parts.append(contentsOf: options.searchMoves.map(\.description))
        }

        if options.ponder {
            parts.append("ponder")
        }

        appendOption("wtime", options.whiteTimeMilliseconds, to: &parts)
        appendOption("btime", options.blackTimeMilliseconds, to: &parts)
        appendOption("winc", options.whiteIncrementMilliseconds, to: &parts)
        appendOption("binc", options.blackIncrementMilliseconds, to: &parts)
        appendOption("movestogo", options.movesToGo, to: &parts)
        appendOption("depth", options.depth, to: &parts)
        appendOption("nodes", options.nodes, to: &parts)
        appendOption("mate", options.mate, to: &parts)
        appendOption("movetime", options.moveTimeMilliseconds, to: &parts)

        if options.infinite {
            parts.append("infinite")
        }

        return UCICommand(rawValue: parts.joined(separator: " "))
    }

    private static func appendOption(_ name: String, _ value: Int?, to parts: inout [String]) {
        guard let value else { return }
        parts.append(name)
        parts.append(String(value))
    }
}

/// Base position used in a UCI `position` command.
public enum UCIPosition: Equatable, Sendable {
    /// The standard chess starting position.
    case startpos

    /// A Forsyth-Edwards Notation position.
    case fen(String)

    fileprivate var commandText: String {
        switch self {
        case .startpos:
            return "startpos"
        case .fen(let fen):
            return "fen \(fen)"
        }
    }
}

/// Search options used to build a UCI `go` command.
public struct UCIGoOptions: Equatable, Sendable {
    /// Restricts search to the supplied legal moves.
    public var searchMoves: [Move]

    /// Enables ponder search.
    public var ponder: Bool

    /// White clock time in milliseconds.
    public var whiteTimeMilliseconds: Int?

    /// Black clock time in milliseconds.
    public var blackTimeMilliseconds: Int?

    /// White increment in milliseconds.
    public var whiteIncrementMilliseconds: Int?

    /// Black increment in milliseconds.
    public var blackIncrementMilliseconds: Int?

    /// Estimated moves until the next time control.
    public var movesToGo: Int?

    /// Maximum search depth in plies.
    public var depth: Int?

    /// Maximum searched nodes.
    public var nodes: Int?

    /// Search for mate in this many moves.
    public var mate: Int?

    /// Fixed move time in milliseconds.
    public var moveTimeMilliseconds: Int?

    /// Searches until a later `stop` command.
    public var infinite: Bool

    /// Creates search options for a UCI `go` command.
    public init(
        searchMoves: [Move] = [],
        ponder: Bool = false,
        whiteTimeMilliseconds: Int? = nil,
        blackTimeMilliseconds: Int? = nil,
        whiteIncrementMilliseconds: Int? = nil,
        blackIncrementMilliseconds: Int? = nil,
        movesToGo: Int? = nil,
        depth: Int? = nil,
        nodes: Int? = nil,
        mate: Int? = nil,
        moveTimeMilliseconds: Int? = nil,
        infinite: Bool = false
    ) {
        self.searchMoves = searchMoves
        self.ponder = ponder
        self.whiteTimeMilliseconds = whiteTimeMilliseconds
        self.blackTimeMilliseconds = blackTimeMilliseconds
        self.whiteIncrementMilliseconds = whiteIncrementMilliseconds
        self.blackIncrementMilliseconds = blackIncrementMilliseconds
        self.movesToGo = movesToGo
        self.depth = depth
        self.nodes = nodes
        self.mate = mate
        self.moveTimeMilliseconds = moveTimeMilliseconds
        self.infinite = infinite
    }

    /// Creates a depth-limited search.
    public static func depth(_ depth: Int, searchMoves: [Move] = []) -> UCIGoOptions {
        UCIGoOptions(searchMoves: searchMoves, depth: depth)
    }

    /// Creates a fixed-time search.
    public static func moveTime(milliseconds: Int, searchMoves: [Move] = []) -> UCIGoOptions {
        UCIGoOptions(searchMoves: searchMoves, moveTimeMilliseconds: milliseconds)
    }

    /// Creates a search that runs until a later `stop` command.
    public static func infiniteSearch(searchMoves: [Move] = []) -> UCIGoOptions {
        UCIGoOptions(searchMoves: searchMoves, infinite: true)
    }
}

private extension Array where Element == Move {
    var uciCommandText: String {
        map(\.description).joined(separator: " ")
    }
}
