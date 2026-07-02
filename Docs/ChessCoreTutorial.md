# ChessCore Tutorial

This tutorial introduces `ChessCore`, the non-UI module in SwiftChessTools.
`ChessCore` owns chess positions, legal move generation, game status, FEN, SAN,
and PGN. `ChessUI` can render values produced by `ChessCore`, but it does not
own chess rules or game-record parsing.

The working model:

> `Position` stores a complete board state, `Game` applies legal moves, SAN
> names moves in context, PGN stores validated game records, and status APIs
> explain whether a game is ongoing, won, drawn, or claimable.

## 1. Install And Import

Add SwiftChessTools as a package dependency, then depend on the `ChessCore`
product from your target.

```swift
import ChessCore
```

For local development in this workspace, use a path dependency:

```swift
.package(path: "../SwiftChessTools")
```

## 2. The Fastest Useful Program

Start a standard chess game, apply legal coordinate moves, inspect status, and
export the current position as FEN:

```swift
let game = Game()

try game.applyLegal(move: "e2e4")
try game.applyLegal(move: "e7e5")
try game.applyLegal(move: "g1f3")

let fen = FENSerializer().fen(from: game.position)
let legalReplies = game.legalMoves.map(\.description)
let status = game.status
```

Use `applyLegal(move:)` for input from users, engines, files, or services. It
parses coordinate notation and checks legality before mutating the game.

`Game.apply(move:)` is still available for internal code that already has a
legal move, but it deliberately assumes legality.

## 3. Core Types

These are the types most apps use first:

- `Square`: a coordinate such as `e4`.
- `Piece`: a piece kind and color.
- `Move`: a concrete coordinate move such as `e2e4` or `e7e8q`.
- `Board`: piece placement only.
- `Position`: board plus side to move, castling rights, en-passant target, and
  move counters.
- `Game`: a playable wrapper around `Position` with legal moves, move history,
  repetition state, draw claims, and status.

Use `Position` when you need to store, validate, or serialize one board state.
Use `Game` when moves are involved.

## 4. Standard Starting Position

For normal chess, use the standard entry points:

```swift
let position = Position.standard
let fen = Position.standardStartingFEN
let game = Game()
```

`Position.standardStartingFEN` is the full six-field FEN:

```text
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

`Game()` is equivalent to `Game(position: .standard)`.

## 5. FEN Parsing And Export

FEN is the most compact way to load or store a complete position.

```swift
let serializer = FENSerializer()
let position = try serializer.position(from: fenText)
let exported = serializer.fen(from: position)
```

`position(from:)` checks FEN syntax: six fields, piece placement, active color,
castling field syntax, en-passant square syntax, and move-counter syntax.

For external FEN, prefer strict semantic validation:

```swift
let position = try FENSerializer().validatedPosition(from: fenText)
```

Semantic validation rejects internally inconsistent positions, including:

- missing or multiple kings
- pawns on the first or eighth rank
- castling rights without the matching king and rook
- invalid en-passant targets
- en-passant targets with a nonzero halfmove clock
- positions where the inactive side's king is already in check

Use syntax-only parsing when you intentionally need to inspect malformed chess
states, migration data, or legacy fixtures.

## 6. Non-Throwing FEN Diagnostics

Use `validationResult(for:)` when you want UI-friendly diagnostics without
throwing control flow:

```swift
let result = FENSerializer().validationResult(for: fenText)

switch result {
case .valid(let position):
    print("Ready: \(position)")

case .invalidSyntax(let error):
    print("Malformed FEN: \(error.description)")

case .invalidPosition(let validation):
    for issue in validation.issues {
        print("Position issue: \(issue.description)")
    }
}
```

If you already have a parsed `Position`, validate it directly:

```swift
let validation = PositionValidator().validationResult(for: position)

if validation.isValid {
    let playable = try validation.validatedPosition()
    print(playable)
} else {
    print(validation.issues)
}
```

`FENValidationResult.validatedPosition()` and
`PositionValidationResult.validatedPosition()` bridge back to the throwing API
when that is more convenient.

## 7. Inspecting Positions

Read pieces by square or coordinate:

```swift
let e4 = Square(coordinate: "e4")
let pieceOnE4 = position.board[e4]
let pieceOnE2 = position.board["e2"]
```

Enumerate occupied squares:

```swift
for (square, piece) in position.board.enumeratedPieces() {
    print("\(square.coordinate): \(piece)")
}
```

Inspect the non-board state:

```swift
let sideToMove = position.state.turn
let castlingRights = position.state.castlingRights
let enPassantTarget = position.state.enPassant
let halfmoveClock = position.counter.halfMoves
let fullmoveNumber = position.counter.fullMoves
```

Those fields are why a `Board` alone is not enough to decide legal moves.

## 8. Coordinate Moves

Coordinate moves use source and destination squares, plus an optional promotion
piece:

```swift
let e4 = try Move(string: "e2e4")
let promotion = try Move(string: "e7e8Q")
```

`Move.description` returns normalized coordinate notation:

```swift
print(e4.description)        // e2e4
print(promotion.description) // e7e8q
```

To apply app-boundary input safely:

```swift
let game = Game()
try game.applyLegal(move: "e2e4")
```

To validate a parsed `Move` before applying it:

```swift
let move = try Move(string: "g1f3")
try game.applyLegal(move: move)
```

If the move is malformed, `applyLegal(move: String)` throws `MoveParsingError`.
If the move is well-formed but illegal in the current position, it throws
`GameApplyError.illegalMove`.

Use `legalMoves` when you need to drive UI affordances:

```swift
let legalCoordinateMoves = game.legalMoves.map(\.description)
```

## 9. Replaying Move Lists

Use `Game.replay(initialPosition:moves:)` when you already have concrete moves
and want ChessCore to rebuild the resulting position, counters, history, and
repetition state:

```swift
let moves = try ["e2e4", "e7e5", "g1f3"].map { try Move(string: $0) }
let replayed = try Game.replay(initialPosition: .standard, moves: moves)
```

`Game(position:moveHistory:)` stores `moveHistory` as metadata only. It does not
replay moves or rebuild counters. Use `Game.replay` for validated
reconstruction.

## 10. SAN

SAN is Standard Algebraic Notation: `Nf3`, `exd5`, `O-O`, `e8=Q`, `Qxf7#`.

SAN always needs game context. The same SAN text can resolve differently in
different positions, and correct spelling can depend on capture, promotion,
check, checkmate, and disambiguation.

Convert a legal move to SAN:

```swift
let game = Game()
let move = try Move(string: "e2e4")
let san = SANSerializer().san(for: move, in: game) // e4
```

Parse SAN back to a concrete move:

```swift
let game = Game()
let move = try SANSerializer().move(for: "e4", in: game)
try game.applyLegal(move: move)
```

Replay SAN movetext:

```swift
let game = Game()
let sanMoves = ["e4", "e5", "Nf3", "Nc6", "Bb5"]
let sanSerializer = SANSerializer()

for san in sanMoves {
    let move = try sanSerializer.move(for: san, in: game)
    try game.applyLegal(move: move)
}
```

`SANSerializer` handles quiet moves, captures, checks, checkmates, castling,
promotion, promotion captures, en-passant captures, and disambiguation.

When SAN parsing fails, treat it as a validation failure for the current game
state, not just a malformed string.

## 11. Game Status And Outcome

`Game.status` describes the current game state:

```swift
switch game.status {
case .ongoing(let drawClaims):
    if drawClaims.contains(.threefoldRepetition) {
        print("Threefold repetition can be claimed.")
    }

case .checkmate(let winner):
    print("\(winner) won by checkmate.")

case .draw(let reason):
    print("Draw: \(reason)")
}
```

Convenience properties cover common UI and app logic:

```swift
if game.isCheck {
    print("Check")
}

if game.isStalemate {
    print("Stalemate")
}

if game.isDraw {
    print("Automatic or claimed draw")
}

if let outcome = game.outcome {
    print("Final outcome: \(outcome)")
}
```

Terminal statuses include:

- checkmate
- stalemate
- insufficient material
- proven dead position
- seventy-five-move automatic draw
- fivefold repetition automatic draw
- a claimed fifty-move or threefold-repetition draw

Claimable statuses are represented separately:

```swift
if game.drawClaims.contains(.fiftyMoveRule) {
    try game.claimDraw(.fiftyMoveRule)
}
```

After a successful claim, `game.status` becomes `.draw(.fiftyMoveRule)` or
`.draw(.threefoldRepetition)`.

## 12. Dead-Position Behavior

FIDE dead positions are positions where neither side can possibly checkmate by
any legal sequence of moves.

`Game.status` reports:

- `.draw(.insufficientMaterial)` for standard material-only dead positions
- `.draw(.deadPosition)` for other dead positions ChessCore can prove

Use `DeadPositionAnalyzer` directly when you need the same question for a raw
`Position`:

```swift
let analyzer = DeadPositionAnalyzer()

if analyzer.hasInsufficientMatingMaterial(in: position) {
    print("Draw by insufficient material.")
}

if analyzer.isDeadPosition(position) {
    print("Neither side can ever checkmate.")
}
```

The analyzer is conservative. If `isDeadPosition(_:)` returns `true`, ChessCore
has proved a FIDE-recognized dead position. If it returns `false`, that means
"not proven dead by this analyzer," not "definitely live."

The current analyzer proves material-only cases, sealed immobile pawn-barrier
cases, and bounded legal-state reachability cases for narrow structural
candidates. It avoids false positives and expensive broad endgame searches by
leaving uncertain positions ongoing.

## 13. PGN Import

PGN is Portable Game Notation: tag pairs, movetext, comments, annotations, and a
result marker.

`PGNSerializer` first parses PGN syntax, then semantically replays every SAN
move through `Game` and `SANSerializer`. Parsed move records therefore contain
validated concrete `Move` values, not just strings.

Parse one game:

```swift
let pgnText = """
    [Event "Example"]
    [Site "?"]
    [Date "????.??.??"]
    [Round "?"]
    [White "White"]
    [Black "Black"]
    [Result "1-0"]

    1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0
    """

let pgnGame = try PGNSerializer().game(from: pgnText)
```

Read the core game data:

```swift
let tags = pgnGame.tagPairs
let result = pgnGame.result
let moves = pgnGame.mainlineMoves
let records = pgnGame.moveRecords
let finalFEN = FENSerializer().fen(from: pgnGame.finalPosition)
```

Read tags by name:

```swift
let white = pgnGame.tagValue(for: "White") ?? "?"
let black = pgnGame.tagValue(for: "Black") ?? "?"
```

Use `games(from:)` for PGN database text containing multiple games:

```swift
let games = try PGNSerializer().games(from: databaseText)
```

Supported PGN features include mainline SAN, tag pairs, FEN-backed games,
comments, semicolon comments, empty comments, Lichess clock/eval/EMT comments,
numeric annotation glyphs, symbolic annotation suffixes, UTF-8 BOM input, `%`
escape lines, and repeated nonstandard tags.

Recursive annotation variations are detected and rejected as future API until
ChessCore has a public move-tree model.

## 14. PGN Move Records

`PGNMoveRecord` is where raw PGN movetext becomes validated chess data.

Important fields:

- `ply`: one-based half-move index in the mainline
- `moveNumber`: full move number
- `color`: side that made the move
- `sourceSAN`: SAN token from the PGN source after symbolic annotation suffixes
  are removed
- `san`: canonical SAN generated by ChessCore
- `move`: concrete resolved `Move`
- `comments`: comments attached to the move
- `nags`: numeric annotation glyphs attached to the move

Print a compact move list:

```swift
for record in pgnGame.moveRecords {
    let prefix = record.color == .white
        ? "\(record.moveNumber)."
        : "\(record.moveNumber)..."

    print("\(prefix) \(record.san) \(record.move.description)")
}
```

Compare source SAN with canonical SAN:

```swift
for record in pgnGame.moveRecords where record.sourceSAN != record.san {
    print("Source \(record.sourceSAN) normalized to \(record.san)")
}
```

Comments and NAGs are preserved:

```swift
for record in pgnGame.moveRecords {
    for comment in record.comments {
        print("Comment after \(record.san): \(comment)")
    }

    for nag in record.nags {
        print("NAG after \(record.san): \(nag)")
    }
}
```

## 15. PGN Result And Status Validation

`PGNGame.finalStatus` stores the status after ChessCore replays the mainline.

```swift
let status = pgnGame.finalStatus
let outcome = pgnGame.finalOutcome
```

PGN import and export reject result markers that contradict terminal statuses
ChessCore can prove:

- checkmate for White requires `1-0`
- checkmate for Black requires `0-1`
- automatic draws require `1/2-1/2`

Ongoing final positions may still carry decisive or drawn results because real
PGNs often end by resignation, timeout, adjudication, or draw agreement before
the board position itself is terminal.

Use these helpers when explaining an imported game:

```swift
if let required = pgnGame.requiredResultForFinalStatus {
    print("Terminal status requires result \(required)")
}

if !pgnGame.resultMatchesFinalStatus {
    print("PGN result conflicts with final status")
}
```

For games parsed by `PGNSerializer`, result/status conflicts have already been
rejected. The helpers are most useful when displaying status or when validating
manually constructed `PGNGame` values before export.

## 16. FEN-Backed PGNs

Most PGNs start from the standard position. Setup PGNs start from an explicit
FEN:

```pgn
[SetUp "1"]
[FEN "4k3/8/8/8/8/8/P7/4K3 w - - 0 1"]
```

Parse them normally:

```swift
let game = try PGNSerializer().game(from: fenBackedPGN)
let initial = game.initialPosition
let final = game.finalPosition
```

Export from a custom initial position:

```swift
let initialPosition = try FENSerializer().validatedPosition(
    from: "4k3/8/8/8/8/8/P7/4K3 w - - 0 1"
)

let exported = try PGNSerializer().pgn(
    initialPosition: initialPosition,
    moves: [try Move(string: "a2a4")],
    tags: [PGNTagPair(name: "Event", value: "Promotion Race")],
    result: .unfinished
)
```

When exporting from a non-standard initial position, `PGNSerializer` adds
`SetUp` and `FEN` tags automatically.

## 17. PGN Export

Export a parsed `PGNGame`:

```swift
let exported = try PGNSerializer().pgn(from: pgnGame)
```

Build and export a game from concrete moves:

```swift
let moves = [
    try Move(string: "e2e4"),
    try Move(string: "e7e5"),
    try Move(string: "g1f3"),
]

let exported = try PGNSerializer().pgn(
    moves: moves,
    tags: [
        PGNTagPair(name: "Event", value: "Generated Example"),
        PGNTagPair(name: "White", value: "Alice"),
        PGNTagPair(name: "Black", value: "Bob"),
    ],
    result: .unfinished
)
```

Control movetext wrapping:

```swift
let compact = try PGNSerializer().pgn(from: pgnGame, lineWidth: 0)
let wrapped = try PGNSerializer().pgn(from: pgnGame, lineWidth: 80)
```

Round trip exported PGN:

```swift
let reparsed = try PGNSerializer().game(from: exported)

precondition(reparsed.mainlineMoves == pgnGame.mainlineMoves)
precondition(reparsed.finalPosition == pgnGame.finalPosition)
```

The exporter writes a deterministic reduced export style. It emits the standard
seven tag roster first, preserves nonstandard tags, escapes tag strings, writes
comments and NAGs, and validates supplied `PGNGame` models before serialization.

## 18. Error Handling

ChessCore uses typed errors:

- `MoveParsingError`: malformed coordinate move text
- `GameApplyError`: a well-formed move is illegal in the current position
- `FENParsingError`: malformed FEN syntax
- `PositionValidationError`: syntactically valid FEN failed semantic validation
- `SANParsingError`: SAN does not identify exactly one legal move
- `PGNParsingError`: malformed PGN or semantic replay failure
- `PGNSerializationError`: invalid move list or inconsistent `PGNGame` export
- `GameReplayError`: illegal move during replay
- `GameDrawClaimError`: unavailable draw claim

Handle PGN failures with context:

```swift
do {
    _ = try PGNSerializer().game(from: pgnText)
} catch PGNParsingError.unsupportedRecursiveVariation(let context) {
    print("Variations are not supported yet: \(context)")
} catch PGNParsingError.resultMismatch(let tag, let movetext, let context) {
    print("Result tag \(tag) does not match \(movetext) at \(context)")
} catch PGNParsingError.resultConflictsWithFinalStatus(let result, let status, let context) {
    print("Result \(result) conflicts with final status \(status) at \(context)")
} catch let error as PGNParsingError {
    print(error.description)
}
```

PGN errors often include game index, ply, move number, token text, or source
location through `PGNParsingContext`.

## 19. Building Move-List Records

`ChessMoveRecordBuilder` builds display-ready SAN move records for UI code
without requiring a full PGN:

```swift
let moves = try ["e2e4", "e7e5", "g1f3"].map { try Move(string: $0) }
let records = try ChessMoveRecordBuilder().records(
    initialPosition: .standard,
    moves: moves
)
```

Each `ChessMoveRecord` contains ply, full move number, side, coordinate move,
and SAN. `ChessUI` can render these records, but the builder itself stays in
`ChessCore`.

## 20. Testing Your Integration

Good ChessCore tests assert concrete chess facts.

Final FEN assertion:

```swift
let game = try PGNSerializer().game(from: pgnText)
let finalFEN = FENSerializer().fen(from: game.finalPosition)

#expect(finalFEN == "r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4")
```

PGN export and reparse:

```swift
let original = try PGNSerializer().game(from: pgnText)
let exported = try PGNSerializer().pgn(from: original)
let reparsed = try PGNSerializer().game(from: exported)

#expect(reparsed.mainlineMoves == original.mainlineMoves)
#expect(reparsed.finalPosition == original.finalPosition)
```

Malformed PGN assertion:

```swift
do {
    _ = try PGNSerializer().game(from: badPGN)
    Issue.record("Expected PGN parsing to fail")
} catch PGNParsingError.unterminatedComment(_) {
    // Expected.
}
```

Useful categories:

- final FEN for known games
- legal move counts for known positions
- FEN syntax and semantic validation failures
- SAN round trips from legal positions
- PGN parse, export, and reparse
- PGN dialect fixtures from Lichess-style input
- terminal result/status conflicts
- dead-position positives and false-positive guards
- generated legal-game invariants

If an expected move count, status, or SAN spelling is not obvious, cross-check
it with an independent tool before committing it as a fixture.

## 21. Runnable Example

See [Examples/ChessCoreRecipes](../Examples/ChessCoreRecipes) for a small
command-line example that parses PGN from standard input, prints tags, final
FEN, final status, and normalized PGN, then demonstrates FEN validation and
safe move application.

Run it from the package root:

```sh
swift run --package-path Examples/ChessCoreRecipes
```

Or pipe PGN into it:

```sh
cat game.pgn | swift run --package-path Examples/ChessCoreRecipes
```

## 22. Using ChessCore With A UI

After `ChessCore` has parsed or built a game record, pass the values your UI
needs into your presentation layer:

```swift
let pgnGame = try PGNSerializer().game(from: pgnText)
let displayedPosition = pgnGame.finalPosition
let moveRows = pgnGame.moveRecords
```

For interactive playback, replay `mainlineMoves` up to the selected ply:

```swift
let selectedPly = 12
let playback = try Game.replay(
    initialPosition: pgnGame.initialPosition,
    moves: Array(pgnGame.mainlineMoves.prefix(selectedPly))
)

let positionToDisplay = playback.position
```

That keeps the data pipeline simple: `ChessCore` validates and models chess
data, then your app or `ChessUI` decides how to present it.

## Appendix A: Common Recipes

### Parse One PGN Game

```swift
let game = try PGNSerializer().game(from: pgnText)
```

### Parse A PGN Database

```swift
let games = try PGNSerializer().games(from: databaseText)
```

### Read Tag Values

```swift
let event = game.tagValue(for: "Event") ?? "?"
let site = game.tagValue(for: "Site") ?? "?"
let white = game.tagValue(for: "White") ?? "?"
let black = game.tagValue(for: "Black") ?? "?"
```

### Print All SAN Moves

```swift
let sanMoves = game.moveRecords.map(\.san)
print(sanMoves.joined(separator: " "))
```

### Convert PGN To Coordinate Moves

```swift
let coordinateMoves = game.mainlineMoves.map(\.description)
```

### Get The Final FEN

```swift
let finalFEN = FENSerializer().fen(from: game.finalPosition)
```

### Strictly Validate A FEN Position

```swift
let position = try FENSerializer().validatedPosition(from: fen)
```

### Inspect FEN Validation Issues

```swift
let result = FENSerializer().validationResult(for: fen)

if let syntaxError = result.syntaxError {
    print("Syntax error: \(syntaxError)")
} else if !result.isValid {
    print(result.positionIssues)
}
```

### Start A Standard Game

```swift
let game = Game()
```

### Apply A Legal Coordinate Move

```swift
try game.applyLegal(move: "e2e4")
```

### Replay Concrete Moves

```swift
let game = try Game.replay(initialPosition: .standard, moves: moves)
```

### Claim A Draw

```swift
try game.claimDraw(.threefoldRepetition)
```

### Check Dead Position

```swift
let isDead = DeadPositionAnalyzer().isDeadPosition(position)
```

### Export A PGNGame

```swift
let exported = try PGNSerializer().pgn(from: game)
```

### Export Concrete Moves As PGN

```swift
let exported = try PGNSerializer().pgn(
    moves: moves,
    tags: [PGNTagPair(name: "Event", value: "Generated")],
    result: .unfinished
)
```

### Detect Unsupported Recursive Variations

```swift
do {
    _ = try PGNSerializer().game(from: pgnText)
} catch PGNParsingError.unsupportedRecursiveVariation(let context) {
    print("Unsupported PGN variation at \(context)")
}
```

## Appendix B: Glossary

For terminology, see [ChessCoreGlossary.md](ChessCoreGlossary.md).
