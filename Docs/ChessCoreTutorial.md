# ChessCore Tutorial

This tutorial introduces the `ChessCore` module without using `ChessUI`.
`ChessCore` owns the reusable chess model, rules, and notation APIs in
SwiftChessTools.

The working theme:

> FEN gives you positions, moves mutate positions through `Game`, SAN gives you
> human move notation, and PGN gives you complete validated game records.

## Audience

This tutorial is for Swift developers who want to use `ChessCore` for rules,
move validation, notation, PGN import/export, or chess data processing.

The examples assume you have already added SwiftChessTools as a package
dependency and can import `ChessCore`.

## 1. What ChessCore Is

`ChessCore` is the non-UI layer of SwiftChessTools. It models chess positions,
generates legal moves, applies moves, parses and exports notation, and validates
PGN game records.

Use `ChessCore` when you need:

- board state
- legal moves
- move application
- game status and outcome inspection
- FEN parsing and export
- SAN parsing and export
- PGN parsing and export

Use `ChessUI` later when you want SwiftUI board rendering or board interaction.
UI code should consume values from `ChessCore`; it should not own rules,
notation, PGN parsing, or engine analysis.

Minimal setup:

```swift
import ChessCore
```

## 2. Core Types And Mental Model

The most common model types are:

- `Square`: a board coordinate such as `e4`.
- `Piece`: a piece kind and color, such as white queen or black knight.
- `Move`: a concrete coordinate move such as `e2e4`.
- `Board`: piece placement only.
- `Position`: complete playable state.
- `Game`: playable state plus move history.
- `GameStatus`: current game state, including checkmate, automatic draws, and
  claimable draws.

The key distinction:

- `Board` knows where pieces are.
- `Position` adds side to move, castling rights, en passant target, and move
  counters.
- `Game` wraps a `Position` so you can ask for legal moves, apply moves, and
  track history.

Most app and parser code should use `Game` once moves are involved. Use
`Position` when you only need to store, inspect, or serialize one board state.

## 3. Creating And Inspecting Positions

FEN is the fastest way to create a complete position.

```swift
let fenSerializer = FENSerializer()
let position = try fenSerializer.position(
    from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
)
```

The standard starting position is also available through `PGNSerializer`:

```swift
let startingPosition = try FENSerializer().position(
    from: PGNSerializer.standardStartingFEN
)
```

Export a position back to FEN:

```swift
let fen = fenSerializer.fen(from: position)
```

`position(from:)` validates FEN syntax. Use `validatedPosition(from:)` when
accepting external FEN that should also satisfy ChessCore's semantic position
checks:

```swift
let validated = try fenSerializer.validatedPosition(
    from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
)
```

Semantic validation rejects positions with missing or multiple kings, pawns on
the first or eighth rank, castling rights without the matching king and rook,
invalid en-passant targets, en-passant targets with a nonzero halfmove clock,
or a non-active side whose king is already in check. Keep using
`position(from:)` when you intentionally need syntax-only FEN parsing.

Inspect pieces by square or coordinate:

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

## 4. Working With Moves

Coordinate moves use source and destination squares, with an optional promotion
piece.

```swift
let e4 = try Move(string: "e2e4")
let promotion = try Move(string: "e7e8Q")
```

`Move.description` returns normalized coordinate notation:

```swift
print(e4.description)        // e2e4
print(promotion.description) // e7e8q
```

Create a `Game` when you need legality:

```swift
let game = Game(position: startingPosition)
let move = try Move(string: "e2e4")

if game.legalMoves.contains(move) {
    game.apply(move: move)
}
```

`Game.apply(move:)` assumes the move is legal. Check `game.legalMoves` before
accepting moves from a user, parser, engine, or file.

Reject illegal coordinate moves at the app boundary:

```swift
struct IllegalMoveError: Error {
    let coordinate: String
}

let candidate = try Move(string: "e2e5")

guard game.legalMoves.contains(candidate) else {
    throw IllegalMoveError(coordinate: candidate.description)
}

game.apply(move: candidate)
```

Print all legal coordinate moves:

```swift
let legalCoordinates = game.legalMoves.map(\.description)
print(legalCoordinates.joined(separator: " "))
```

Build a move list from coordinate notation:

```swift
let game = Game(position: startingPosition)
let coordinates = ["e2e4", "e7e5", "g1f3"]

for coordinate in coordinates {
    let move = try Move(string: coordinate)
    guard game.legalMoves.contains(move) else {
        throw IllegalMoveError(coordinate: coordinate)
    }
    game.apply(move: move)
}

let finalPosition = game.position
let moveHistory = game.moveHistory
```

Replay an already-known concrete move list when you want ChessCore to rebuild
the resulting position, move counters, move history, and repetition state:

```swift
let moves = try ["e2e4", "e7e5", "g1f3"].map { try Move(string: $0) }
let replayed = try Game.replay(initialPosition: startingPosition, moves: moves)
```

`Game(position:moveHistory:)` stores `moveHistory` as metadata only. It does not
replay moves or rebuild counters. Use `Game.replay(initialPosition:moves:)` for
validated reconstruction.

Inspect status and outcome after moves:

```swift
switch game.status {
case .ongoing(let drawClaims):
    if drawClaims.contains(.threefoldRepetition) {
        print("A threefold repetition claim is available.")
    }
case .checkmate(let winner):
    print("\(winner) won by checkmate.")
case .draw(let reason):
    print("Draw: \(reason)")
}
```

For simpler app logic, use the convenience properties:

```swift
if game.isStalemate {
    print("Stalemate")
}

if game.isDraw {
    print("Automatic draw")
}

if let outcome = game.outcome {
    print("Final outcome: \(outcome)")
}
```

`Game.drawClaims` reports claimable draw rules for the current position, such as
the fifty-move rule or threefold repetition. `Game.status` reports automatic
draws such as stalemate, insufficient material, dead position, the
seventy-five-move rule, and fivefold repetition.

Material-only dead positions are reported as `.draw(.insufficientMaterial)` for
compatibility with common chess terminology. Other proven FIDE dead positions,
such as sealed immobile pawn barriers where neither side can ever reach mate,
are reported as `.draw(.deadPosition)`.

Use `DeadPositionAnalyzer` directly when you need to ask the same question for a
raw `Position`:

```swift
let analyzer = DeadPositionAnalyzer()

if analyzer.hasInsufficientMatingMaterial(in: game.position) {
    print("Draw by insufficient material.")
}

if analyzer.isDeadPosition(game.position) {
    print("Neither side can ever checkmate.")
}
```

`DeadPositionAnalyzer` is conservative. If it cannot prove that the position is
dead, it returns `false` and `Game.status` remains ongoing unless another
terminal rule applies.

Claim an available draw explicitly:

```swift
if game.drawClaims.contains(.fiftyMoveRule) {
    try game.claimDraw(.fiftyMoveRule)
}
```

After a successful claim, `game.status` becomes `.draw(.fiftyMoveRule)` or
`.draw(.threefoldRepetition)`. Terminal positions such as checkmate, stalemate,
insufficient material, seventy-five-move automatic draws, and fivefold
repetition do not expose claimable draws. A claimed draw is also terminal for
`drawClaims`; use `claimedDraw` to inspect which claim was made.

Reset a reusable game object to a new position:

```swift
game.reset(to: startingPosition)
```

`reset(to:)` replaces the position, clears derived repetition state, clears any
claimed draw, and optionally stores metadata-only move history.

## 5. SAN Notation

SAN is Standard Algebraic Notation, such as `Nf3`, `exd5`, `O-O`, `e8=Q`, or
`Qxf7#`.

SAN requires position context. The same SAN text can resolve differently in
different positions, and the correct spelling can depend on check, checkmate,
captures, promotion, and disambiguation.

Convert a legal move to SAN:

```swift
let game = Game(position: startingPosition)
let serializer = SANSerializer()
let move = try Move(string: "e2e4")

let san = serializer.san(for: move, in: game) // e4
```

Parse SAN back to a concrete move:

```swift
let parsedMove = try serializer.move(for: "e4", in: game)
game.apply(move: parsedMove)
```

Replay a SAN sequence through a `Game`:

```swift
let game = Game(position: startingPosition)
let sanMoves = ["e4", "e5", "Nf3", "Nc6", "Bb5"]
let sanSerializer = SANSerializer()

for san in sanMoves {
    let move = try sanSerializer.move(for: san, in: game)
    game.apply(move: move)
}
```

Common SAN cases that `SANSerializer` handles:

- quiet moves: `Nf3`
- captures: `Bxc4`
- checks: `Qh5+`
- checkmate: `Qxf7#`
- castling: `O-O` and `O-O-O`
- promotion: `e8=Q`
- promotion captures: `cxb8=Q#`
- disambiguation: `Nbd2`, `R1e2`, `Qh4e1`

When SAN parsing fails, treat it as a validation failure for the current game
state, not just a malformed string.

## 6. PGN Import Basics

PGN is Portable Game Notation: tags, movetext, comments, annotations, and a
result marker. `PGNSerializer` parses PGN syntax first, then validates every SAN
move by replaying it through `Game`.

Parse one PGN game:

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

let serializer = PGNSerializer()
let pgnGame = try serializer.game(from: pgnText)
```

Read the core game data:

```swift
let tags = pgnGame.tagPairs
let result = pgnGame.result
let moves = pgnGame.mainlineMoves
let records = pgnGame.moveRecords
let finalFEN = FENSerializer().fen(from: pgnGame.finalPosition)
```

Read a specific tag:

```swift
let white = pgnGame.tagValue(for: "White") ?? "?"
let black = pgnGame.tagValue(for: "Black") ?? "?"
```

Export the parsed game back to deterministic PGN:

```swift
let exported = try serializer.pgn(from: pgnGame)
```

The first PGN milestone supports validated mainlines, tag pairs, comments, NAGs,
FEN-backed games, UTF-8 BOM input, and multi-game database parsing. Recursive
annotation variations are detected and reported as unsupported until ChessCore
grows a PGN tree model.

PGN result markers are checked against terminal final positions. If replay ends
in checkmate, the result must name the winning side. If replay ends in an
automatic draw, the result must be `1/2-1/2`. Ongoing positions can still carry a
decisive or drawn result because real PGNs may end by resignation, timeout, or
agreement before the board position is terminal.

Use `finalStatus`, `finalOutcome`, and `resultMatchesFinalStatus` when a PGN
browser, importer, or training tool needs to explain the final state:

```swift
let finalStatus = pgnGame.finalStatus
let finalOutcome = pgnGame.finalOutcome

if !pgnGame.resultMatchesFinalStatus {
    print("Result \(pgnGame.result) conflicts with \(finalStatus)")
}
```

## 7. PGN Move Records

`PGNMoveRecord` is where raw PGN movetext becomes validated chess data.

Important fields:

- `ply`: one-based half-move index in the mainline.
- `moveNumber`: full move number.
- `color`: side that made the move.
- `sourceSAN`: SAN token from the PGN source after symbolic annotations are
  normalized.
- `san`: canonical SAN generated by ChessCore.
- `move`: concrete resolved `Move`.
- `comments`: comments attached to the move.
- `nags`: numeric annotation glyphs attached to the move.

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

Read comments and NAGs:

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

Lichess clock and evaluation comments are preserved as ordinary PGN comments.

## 8. PGN Databases

A PGN database is text containing one or more games. Use `games(from:)` when a
file may contain multiple games.

```swift
let games = try PGNSerializer().games(from: databaseText)
print("Imported \(games.count) games")
```

Print common tags:

```swift
for game in games {
    let event = game.tagValue(for: "Event") ?? "?"
    let white = game.tagValue(for: "White") ?? "?"
    let black = game.tagValue(for: "Black") ?? "?"
    let result = game.result

    print("\(event): \(white) vs \(black), \(result)")
}
```

Filter by tag:

```swift
let carlsenGames = games.filter { game in
    game.tagValue(for: "White") == "Carlsen, Magnus"
        || game.tagValue(for: "Black") == "Carlsen, Magnus"
}
```

Collect final positions for analysis or indexing:

```swift
let finalFENs = games.map { game in
    FENSerializer().fen(from: game.finalPosition)
}
```

For large import pipelines, keep parsing deterministic: read text, parse games,
validate records, then transform into your app's storage model.

## 9. FEN-Backed PGNs

Most PGNs start from the standard chess starting position. Some start from a
custom position using both tags:

```pgn
[SetUp "1"]
[FEN "4k3/8/8/8/8/8/P7/4K3 w - - 0 1"]
```

Parse a FEN-backed game the same way:

```swift
let game = try PGNSerializer().game(from: fenBackedPGN)
let initial = game.initialPosition
let final = game.finalPosition
```

Verify the initial position:

```swift
let initialFEN = FENSerializer().fen(from: game.initialPosition)
print(initialFEN)
```

Export moves from an explicit initial position:

```swift
let initialPosition = try FENSerializer().position(
    from: "4k3/8/8/8/8/8/P7/4K3 w - - 0 1"
)

let exported = try PGNSerializer().pgn(
    initialPosition: initialPosition,
    moves: [try Move(string: "a2a4")],
    tags: [PGNTagPair(name: "Event", value: "Promotion Race")],
    result: .unfinished
)
```

When exporting from a non-standard initial position, `PGNSerializer` includes
`SetUp` and `FEN` tags automatically.

## 10. Exporting PGN

Export an imported `PGNGame`:

```swift
let exported = try PGNSerializer().pgn(from: pgnGame)
```

Export concrete moves from the standard starting position:

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

The exporter writes a standard seven tag roster, preserves non-standard tags,
adds a `Result` tag matching the game result, and includes setup tags when the
initial position is not the standard starting position.

## 11. Handling Errors

ChessCore parser and serializer errors are typed.

Common errors:

- `MoveParsingError`: malformed coordinate move text.
- `FENParsingError`: malformed FEN.
- `PositionValidationError`: syntactically valid FEN that fails strict semantic
  position validation.
- `SANParsingError`: SAN cannot be parsed in the current game context.
- `PGNParsingError`: malformed PGN or semantic replay failure.
- `PGNSerializationError`: an invalid move list or inconsistent `PGNGame` model
  was supplied for export.
- `GameReplayError`: an illegal move was supplied while replaying a concrete
  move list.
- `GameDrawClaimError`: a draw claim was requested when it is not currently
  available.

Catch PGN parser errors:

```swift
do {
    let game = try PGNSerializer().game(from: pgnText)
    print(game.finalPosition)
} catch let error as PGNParsingError {
    print(error.description)
} catch {
    print(error)
}
```

Handle specific PGN failures:

```swift
do {
    _ = try PGNSerializer().game(from: pgnText)
} catch PGNParsingError.unsupportedRecursiveVariation(let context) {
    print("Variations are not supported yet: \(context)")
} catch PGNParsingError.resultMismatch(let tag, let movetext, let context) {
    print("Result tag \(tag) does not match \(movetext) at \(context)")
} catch PGNParsingError.resultConflictsWithFinalStatus(let result, let status, let context) {
    print("Result \(result) conflicts with final status \(status) at \(context)")
} catch {
    print(error)
}
```

When presenting errors to users, prefer the typed error's description. PGN
errors often include game index, ply, move number, token text, or source
location.

## 12. Testing Your ChessCore Integration

Good ChessCore tests assert concrete chess facts rather than only checking that
parsing did not throw.

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

Useful test categories:

- final FEN for short known games
- FEN round trips for generated legal positions
- SAN round trips for generated legal moves
- PGN parse, export, and reparse
- malformed FEN, SAN, and PGN
- multi-game database parsing
- synthetic edge cases for rules and notation
- Lichess CC0 PGN fixtures for real-world import patterns

If an expected move count or SAN spelling is not obvious, cross-check it with an
independent tool before committing it as a fixture.

## 13. Capstone: Build A Tiny PGN Inspector

This command-line example reads PGN text from standard input, parses one or more
games, prints core tags, prints the mainline, prints the final FEN, and prints
normalized PGN.

```swift
import ChessCore
import Foundation

@main
struct PGNInspector {
    static func main() throws {
        let inputData = FileHandle.standardInput.readDataToEndOfFile()
        let input = String(data: inputData, encoding: .utf8) ?? ""

        let pgnSerializer = PGNSerializer()
        let fenSerializer = FENSerializer()
        let games = try pgnSerializer.games(from: input)

        for (index, game) in games.enumerated() {
            let event = game.tagValue(for: "Event") ?? "?"
            let white = game.tagValue(for: "White") ?? "?"
            let black = game.tagValue(for: "Black") ?? "?"
            let finalFEN = fenSerializer.fen(from: game.finalPosition)

            print("Game \(index + 1)")
            print("Event: \(event)")
            print("Players: \(white) vs \(black)")
            print("Result: \(game.result)")
            print("Moves:")

            for record in game.moveRecords {
                let prefix = record.color == .white
                    ? "\(record.moveNumber)."
                    : "\(record.moveNumber)..."
                print("  \(prefix) \(record.san) [\(record.move)]")
            }

            print("Final FEN: \(finalFEN)")
            print("Normalized PGN:")
            print(try pgnSerializer.pgn(from: game))
        }
    }
}
```

This stays ChessCore-only. There is no SwiftUI board, engine, evaluation, or
display policy.

## 14. Using ChessCore With A UI

After `ChessCore` has parsed or built a game record, pass the values your UI
needs into your presentation layer. For example, a PGN browser might use:

- `PGNGame.tagPairs` for game metadata.
- `PGNGame.moveRecords` for a move list.
- `PGNGame.mainlineMoves` for replay.
- `PGNGame.initialPosition` as the starting board.
- `PGNGame.finalPosition` for indexing, summaries, or final-board display.

`ChessUI` can render boards, legal move hints, and move lists, but your app
still decides which game is selected, which ply is visible, how PGN metadata is
shown, and whether engine analysis is involved.

A typical flow is:

```swift
let pgnGame = try PGNSerializer().game(from: pgnText)
let displayedPosition = pgnGame.finalPosition
let moveRows = pgnGame.moveRecords
```

For interactive playback, replay `mainlineMoves` up to the ply the user
selected:

```swift
let selectedPly = 12
let playback = try Game.replay(
    initialPosition: pgnGame.initialPosition,
    moves: Array(pgnGame.mainlineMoves.prefix(selectedPly))
)

let positionToDisplay = playback.position
```

That keeps the data pipeline simple: `ChessCore` validates and models the chess
record, then your app or `ChessUI` decides how to present it.

## Appendix A: Glossary

For terminology, see [ChessCoreGlossary.md](ChessCoreGlossary.md). The glossary
is kept separate so it can serve both this tutorial and API reference material.

## Appendix B: Common Recipes

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

### Replay Concrete Moves

```swift
let game = try Game.replay(initialPosition: startingPosition, moves: moves)
```

### Claim A Draw

```swift
try game.claimDraw(.threefoldRepetition)
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

### Handle PGNParsingError

```swift
do {
    _ = try PGNSerializer().game(from: pgnText)
} catch let error as PGNParsingError {
    print(error.description)
}
```

### Detect Unsupported Recursive Variations

```swift
do {
    _ = try PGNSerializer().game(from: pgnText)
} catch PGNParsingError.unsupportedRecursiveVariation(let context) {
    print("Unsupported PGN variation at \(context)")
}
```
