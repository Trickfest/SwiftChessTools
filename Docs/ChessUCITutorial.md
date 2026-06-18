# ChessUCI Tutorial

This tutorial introduces `ChessUCI`, the UCI text module in SwiftChessTools.
`ChessUCI` builds command strings sent to a UCI-compatible chess engine and
turns text emitted by the engine into typed Swift values. It builds on
`ChessCore` for coordinate moves and piece colors, but it does not start an
engine, manage engine readiness, schedule searches, or choose moves.

The working model:

> `UCICommand` builds one engine-input line at a time, `UCIParser` parses one
> engine-output line at a time, `UCIIdentification` and `UCIOption` describe
> handshake/configuration output, `UCIBestMove` describes finished-search
> output, `UCIInfoLine` describes streaming search metadata, and score helpers
> normalize side-to-move-relative engine scores into White-positive values for
> UI display.

## 1. Install And Import

Add SwiftChessTools as a package dependency, then depend on the `ChessUCI`
product from your target. Apps that parse moves or normalize scores usually
also depend on `ChessCore`.

```swift
import ChessCore
import ChessUCI
```

For local development in this workspace, use a path dependency:

```swift
.package(path: "../SwiftChessTools")
```

Then add the product your target needs:

```swift
.product(name: "ChessUCI", package: "SwiftChessTools")
```

## 2. Build Engine Commands

Use `UCICommand` to create exact command strings for the common UCI inputs:

```swift
let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

let commands: [UCICommand] = [
    .uci,
    .isReady,
    .newGame,
    .position(.fen(fen)),
    .go(.depth(12)),
]

let textToSend = commands.map(\.string)
```

That produces:

```text
uci
isready
ucinewgame
position fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
go depth 12
```

The app still decides when to send those lines, how to wait for `readyok`, how
to handle timeouts, and whether to cancel or replace a search.

## 3. Positions And Search Limits

Position commands support both `startpos` and FEN input, with optional move
history:

```swift
let moves = [
    try Move(string: "e2e4"),
    try Move(string: "e7e5"),
    try Move(string: "g1f3"),
]

let command = UCICommand.position(.startpos, moves: moves)
print(command.string)
// position startpos moves e2e4 e7e5 g1f3
```

Search commands use `UCIGoOptions`:

```swift
let fixedDepth = UCICommand.go(.depth(14))
let fixedTime = UCICommand.go(.moveTime(milliseconds: 500))
let infinite = UCICommand.go(.infiniteSearch())
```

For clock-based searches or engine analysis modes, build the options directly:

```swift
let options = UCIGoOptions(
    searchMoves: [try Move(string: "e2e4"), try Move(string: "d2d4")],
    whiteTimeMilliseconds: 300_000,
    blackTimeMilliseconds: 295_000,
    whiteIncrementMilliseconds: 2_000,
    blackIncrementMilliseconds: 2_000,
    movesToGo: 30
)

print(UCICommand.go(options).string)
// go searchmoves e2e4 d2d4 wtime 300000 btime 295000 winc 2000 binc 2000 movestogo 30
```

Engine options are also formatted as command values:

```swift
UCICommand.setOption(name: "Hash", value: 128).string
// setoption name Hash value 128

UCICommand.setOption(name: "UCI_AnalyseMode", value: true).string
// setoption name UCI_AnalyseMode value true
```

UCI option names and values are free-form command text. `ChessUCI` preserves
spaces and does not quote or escape values.

Engines that require registration can also use the typed helpers:

```swift
UCICommand.registerLater.string
// register later

UCICommand.register(name: "Example User", code: "ABC 123").string
// register name Example User code ABC 123
```

## 4. The Fastest Useful Parser

Create a parser and pass it one complete engine-output line:

```swift
let parser = UCIParser()
let parsed = parser.parse("bestmove e2e4 ponder e7e5")

if case .bestMove(let bestMove) = parsed {
    print(bestMove.move?.description as Any)   // Optional("e2e4")
    print(bestMove.ponder?.description as Any) // Optional("e7e5")
}
```

The parser is stateless. Keep one parser or create one where needed; either
style is fine.

## 5. Handshake And Configuration Output

During startup, a UCI engine usually emits identification and option lines
before `uciok`, and later emits `readyok` after `isready`:

```swift
let parser = UCIParser()

for line in [
    "id name Stockfish",
    "id author the Stockfish developers",
    "option name Hash type spin default 16 min 1 max 33554432",
    "uciok",
    "readyok",
] {
    switch parser.parse(line) {
    case .id(let id):
        print(id.kind, id.value)

    case .option(let option):
        print(option.name, option.type, option.defaultValue as Any)

    case .uciOK:
        print("UCI handshake complete")

    case .readyOK:
        print("Engine is ready")

    default:
        break
    }
}
```

`UCIOption` preserves free-form names, defaults, and combo values because UCI
option text is not quoted. Supported option types are `check`, `spin`, `combo`,
`button`, and `string`; unrecognized option types are kept as `.unknown(text)`.

The parser also recognizes copy-protection and registration status output:

```swift
UCIParser().parse("copyprotection ok")
// .copyProtection(.ok)

UCIParser().parse("registration checking")
// .registration(.checking)
```

`ChessUCI` parses those records, but the app or engine wrapper still decides
what they mean for startup flow, user prompts, option policy, retries, and
timeouts.

## 6. Best Moves

UCI engines finish a search with a `bestmove` line:

```text
bestmove e2e4 ponder e7e5
```

`ChessUCI` parses that as:

```swift
case .bestMove(let bestMove):
    let move = bestMove.move
    let ponder = bestMove.ponder
```

`move` and `ponder` are `ChessCore.Move` values. A `bestmove (none)` or
`bestmove 0000` line maps to `move == nil`, which lets an app handle
no-legal-move or engine-failure states explicitly.

If the line starts with `bestmove` but contains malformed move text, the parser
still returns `.bestMove` with `nil` move fields. UCI output is an external
stream; callers should handle invalid values at the app boundary.

## 7. Info Lines

During search, engines stream `info` lines. `ChessUCI` extracts common fields:

```swift
let line = "info depth 16 seldepth 24 multipv 2 score cp 85 lowerbound "
    + "nodes 123456 nps 98765 time 4321 hashfull 123 currmove g1f3 "
    + "pv e2e4 e7e5 g1f3"

if case .info(let info) = UCIParser().parse(line) {
    print(info.depth as Any)                  // Optional(16)
    print(info.selectiveDepth as Any)         // Optional(24)
    print(info.multipv as Any)                // Optional(2)
    print(info.score as Any)                  // Optional(.centipawns(85))
    print(info.scoreBound)                    // lowerbound
    print(info.currentMove?.description as Any)
    print(info.principalVariation.map(\.description))
}
```

Supported `info` fields include:

- `depth`
- `seldepth`
- `time`
- `nodes`
- `nps`
- `hashfull`
- `multipv`
- `score cp`
- `score mate`
- `lowerbound` and `upperbound` score markers
- `currmove`
- `currmovenumber`
- `tbhits`
- `sbhits`
- `cpuload`
- `pv`
- `refutation`
- `currline`
- `string`

Unknown fields are ignored. Malformed numeric values or malformed move tokens
do not throw; the parser keeps the fields it can understand.

`pv`, `refutation`, and `currline` are move sequences. `currline` can also
include an optional CPU number before the moves:

```swift
let parsed = UCIParser().parse("info currline 2 e2e4 e7e5 g1f3")

if case .info(let info) = parsed {
    print(info.currentLine?.cpuNumber as Any)          // Optional(2)
    print(info.currentLine?.moves.map(\.description) ?? [])
}
```

## 8. Scores

Raw UCI scores are side-to-move-relative for the position being searched:

```text
info score cp 85
```

If White is to move in the searched position, `cp 85` favors White. If Black is
to move, the same raw score favors Black.

Use `whiteRelativeScore(sideToMove:)` before showing an evaluation in a UI:

```swift
let info = UCIInfoLine(rawLine: "info score cp 85", score: .centipawns(85))
let displayScore = info.whiteRelativeScore(sideToMove: .black)
// .centipawns(-85)
```

Mate scores use the same side-to-move rule. Positive mate values mean the side
to move is mating; negative values mean the side to move is getting mated:

```swift
UCIScore.mate(3).whiteRelative(sideToMove: .white)
// .mate(moves: 3, side: .white)

UCIScore.mate(-2).whiteRelative(sideToMove: .white)
// .mate(moves: 2, side: .black)
```

## 9. MultiPV And Suggestions

Engines can report several candidate lines when configured for MultiPV. A
typical app stores the latest `UCIInfoLine` for each `multipv` value:

```swift
var linesByRank: [Int: UCIInfoLine] = [:]

if case .info(let info) = parser.parse(engineLine),
   let rank = info.multipv {
    linesByRank[rank] = info
}
```

`ChessUCI` does not decide which line is best or how many lines to show. It
only parses the rank, score, and principal variation that the engine emitted.
Apps can pass the first move from each principal variation to `ChessUI` arrows,
a move list, or a custom analysis panel.

## 10. Handing Scores To ChessUI

`ChessUCI` intentionally does not depend on `ChessUI`. Apps that use both
modules can map normalized UCI scores into `ChessEvaluation`:

```swift
import ChessCore
import ChessUI
import ChessUCI

func evaluation(from info: UCIInfoLine, sideToMove: PieceColor) -> ChessEvaluation {
    guard let score = info.whiteRelativeScore(sideToMove: sideToMove) else {
        return .unavailable
    }

    switch score {
    case .centipawns(let centipawns):
        return .centipawns(centipawns)
    case .mate(let moves, let side):
        return .mate(moves: moves, side: side)
    }
}
```

Keep track of the side to move at the moment a search starts. That is the side
the engine score is relative to, even if later UI state changes before the
engine streams another `info` line.

## 11. Unknown Lines

Some UCI output is diagnostic or engine-specific text:

```text
info depth 12 customfield engine-specific text
unexpected-engine-line
```

Unknown `info` fields are skipped so recognized fields from the same line are
still available. Whole lines with unrecognized command names parse as
`.unknown(rawLine)`. Unknown option types, copy-protection statuses, and
registration statuses stay inside their typed records as `.unknown(text)`.

This is deliberate. UCI engines sometimes add private diagnostics; apps can log
or inspect those strings without losing typed coverage for the standard
protocol surface.

## 12. Scope Boundaries

`ChessUCI` provides:

- Command formatting for common engine inputs such as `uci`, `isready`,
  `ucinewgame`, `position`, `go`, `setoption`, `register`, `stop`, and `quit`.
- Typed parsing for `id`, `option`, `uciok`, `readyok`, `copyprotection`, and
  `registration` output.
- `bestmove` and optional `ponder` parsing.
- Official `info` metadata parsing for common search counters, tablebase and
  Shredderbase hits, current move data, principal variations, refutations,
  current lines, free-form strings, and CPU load.
- Centipawn, mate, and score-bound parsing.
- MultiPV rank and principal-variation parsing.
- Side-to-move-relative score normalization helpers.

`ChessUCI` does not provide:

- A chess engine.
- Stockfish integration.
- UCI process lifecycle management.
- Engine option policy or readiness sequencing.
- Search scheduling, cancellation, or throttling.
- Move ranking beyond the `multipv` number emitted by the engine.
- UI rendering.

That boundary lets SwiftChessTools stay reusable while apps decide which engine
to use, how to license it, how to run searches, and how to present results.
