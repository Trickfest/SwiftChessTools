# ChessCore Tutorial Outline

This is a planning outline for a future ChessCore-only tutorial. The tutorial
should teach the reusable chess model, rules, and notation APIs without relying
on ChessUI.

The working theme:

> FEN gives you positions, moves mutate positions through `Game`, SAN gives you
> human move notation, and PGN gives you complete validated game records.

## Audience

Swift developers who are new to SwiftChessTools and want to use `ChessCore` for
rules, move validation, notation, game import/export, or chess data processing.

## Goals

- Explain the ChessCore mental model before introducing notation formats.
- Show practical, copy-pasteable examples for common tasks.
- Keep UI concerns out of the main tutorial.
- Build up to PGN support as the capstone topic.
- Include a glossary and recipe appendix for later reference.

## Proposed Structure

### 1. What ChessCore Is

- `ChessCore` vs. `ChessUI`.
- What ChessCore solves:
  - board state
  - legal moves
  - FEN
  - SAN
  - PGN
- Minimal setup:

```swift
import ChessCore
```

### 2. Core Types And Mental Model

- `Square`
- `Piece`
- `Move`
- `Board`
- `Position`
- `Game`

Core idea:

- `Board` is piece placement.
- `Position` is playable state.
- `Game` is playable state plus move history.

### 3. Creating And Inspecting Positions

- Start from the standard position.
- Load a FEN with `FENSerializer`.
- Export a position back to FEN.
- Inspect pieces on squares.
- Explain active color, castling rights, en passant target, halfmove clock, and
  fullmove number.

Example topics:

- Create the standard starting position.
- Parse a midgame FEN.
- Ask what piece is on `e4`.
- Convert the current position back to FEN.

### 4. Working With Moves

- Create coordinate moves such as `e2e4`.
- Generate legal moves.
- Apply moves through `Game`.
- Reject illegal moves.
- Track final position and move history.

Example topics:

- Apply `e2e4`.
- Try an illegal move and handle failure.
- Print all legal moves from a position.
- Build a move list from coordinate notation.

### 5. SAN Notation

- Convert legal moves to SAN.
- Parse SAN in a live game context.
- Explain why SAN requires position context.
- Cover common notation cases:
  - quiet moves
  - captures
  - checks
  - checkmate
  - castling
  - promotion
  - disambiguation

Example topics:

- Convert `e2e4` to `e4`.
- Parse `Nf3` into a concrete `Move`.
- Parse a short SAN sequence by replaying it through `Game`.

### 6. PGN Import Basics

- Parse one PGN game with `PGNSerializer.game(from:)`.
- Read tag pairs.
- Read the game result.
- Access `mainlineMoves`.
- Access `moveRecords`.
- Get the final position and final FEN.
- Export the parsed game back to PGN.

Example:

```swift
let serializer = PGNSerializer()
let game = try serializer.game(from: pgnText)

let moves = game.mainlineMoves
let finalFEN = FENSerializer().fen(from: game.finalPosition)
let exported = serializer.pgn(from: game)
```

### 7. PGN Move Records

Explain how PGN text becomes validated chess data.

Fields to cover:

- `ply`
- `moveNumber`
- `color`
- `san`
- `sourceSAN`
- `move`
- `comments`
- `nags`

Example topics:

- Print every move number and SAN move.
- Compare source SAN with canonical SAN.
- Convert every PGN move to coordinate move notation.
- Read preserved comments and numeric annotation glyphs.

### 8. PGN Databases

- Use `PGNSerializer.games(from:)`.
- Iterate over many games.
- Filter by tags.
- Extract final positions.
- Build a simple importer pipeline.

Example topics:

- Count games in a PGN database file.
- Print Event, White, Black, and Result for each game.
- Find games where White is a specific player.
- Collect final FENs for analysis or indexing.

### 9. FEN-Backed PGNs

- Explain `[SetUp "1"]`.
- Explain `[FEN "..."]`.
- Parse PGNs from non-standard starting positions.
- Export PGN from an explicit initial position.

Example topics:

- Parse a promotion puzzle PGN.
- Verify `initialPosition`.
- Export moves from a custom starting FEN.

### 10. Exporting PGN

- Export an imported `PGNGame`.
- Export concrete `Move` values.
- Add tags and result.
- Use line wrapping.
- Round trip: parse, inspect, export, parse again.

Example topics:

- Export a generated move list.
- Export with the standard seven tag roster.
- Export a FEN-backed game.
- Assert that reparsed moves match the original moves.

### 11. Handling Errors

- `PGNParsingError`
- `PGNSerializationError`
- Invalid SAN.
- Result tag vs. movetext result mismatch.
- Invalid or missing FEN.
- Unsupported recursive variations.
- How to present useful error text to app users.

Example topics:

- Catch a parser error and print its description.
- Detect unsupported variations.
- Surface the failing game index, token, or move context when available.

### 12. Testing Your ChessCore Integration

- Round-trip tests.
- Final FEN assertions.
- Invalid PGN assertions.
- Multi-game fixture tests.
- Synthetic edge cases.
- Lichess-derived corpus tests, with licensing note.

Example topics:

- Test a short known game against an expected final FEN.
- Test parser failure for malformed PGN.
- Test export and reparse.
- Test several deterministic generated games.

### 13. Capstone: Build A Tiny PGN Inspector

Build a small command-line tool or package example that:

- reads PGN text
- parses one or more games
- prints core tags
- prints the mainline move list
- prints the final FEN
- exports normalized PGN

This should stay ChessCore-only. No SwiftUI, no board rendering, and no engine.

### 14. Where ChessUI Fits Later

Keep this short and near the end.

- ChessUI can display positions, boards, legal move hints, and move lists.
- Apps can choose how much PGN metadata to show.
- PGN parsing, validation, and game-record modeling should remain ChessCore
  responsibilities.

## Appendix A: ChessCore Glossary

The glossary should live near the end of the tutorial after readers have seen
the concepts in context.

### Package And API Terms

- **ChessCore**: The package module for chess rules, game state, notation, and
  game-record parsing/export.
- **ChessUI**: The package module for SwiftUI board display and UI components.
  It should consume ChessCore values rather than parse or own game-record logic.
- **Board**: Piece placement only. A board does not fully describe a playable
  game state by itself.
- **Position**: Board plus active color, castling rights, en passant target, and
  move counters.
- **Game**: A playable wrapper around `Position` that applies moves and tracks
  move history.
- **Move**: A concrete coordinate move, such as `e2e4`.
- **Move History**: The sequence of concrete moves applied through `Game`.
- **Initial Position**: The position used before replaying a move list or PGN
  mainline. This is usually the standard starting position, but it can come from
  a FEN tag.
- **Final Position**: The position after all moves have been replayed.

### Chess And Rules Terms

- **Legal Move**: A move allowed by chess rules from the current position.
- **Pseudo-Legal Move**: A move that follows piece movement rules but may still
  leave the moving side's king in check, if this concept is exposed or useful in
  internals.
- **Ply**: One half-move. White's first move is ply 1, Black's reply is ply 2.
- **Move Number**: The full chess move number. White's and Black's first moves
  both have move number 1.
- **Active Color**: The side whose turn it is to move.
- **Castling Rights**: The current ability for either side to castle king-side
  or queen-side.
- **En Passant Target**: The square recorded after a two-square pawn move that
  may allow an en passant capture on the next move.
- **Halfmove Clock**: The FEN counter used for the fifty-move rule.
- **Fullmove Number**: The FEN move number, incremented after Black moves.

### Notation Terms

- **FEN**: Forsyth-Edwards Notation, a text format for one chess position.
- **SAN**: Standard Algebraic Notation, the human-readable move notation used in
  PGN movetext, such as `Nf3`, `exd5`, `O-O`, or `Qxf7#`.
- **PGN**: Portable Game Notation, a text format for complete game records,
  including tags, moves, comments, annotations, and result.
- **Coordinate Move**: A move written by source and destination squares, such as
  `e2e4` or `e7e8Q`.
- **Source SAN**: The SAN token as it appeared in the original PGN text.
- **Canonical SAN**: SAN produced by `SANSerializer` after validating a concrete
  move in context.

### PGN Terms

- **Tag Pair**: PGN metadata such as `[White "Fischer"]`.
- **Seven Tag Roster**: The standard PGN tags: `Event`, `Site`, `Date`,
  `Round`, `White`, `Black`, and `Result`.
- **Movetext**: The move section of a PGN game after the tag pairs.
- **Mainline**: The primary sequence of moves in a PGN game.
- **Variation**: An alternate line in PGN, written in parentheses. First-pass
  ChessCore PGN support detects variations but reports them as unsupported.
- **Comment**: Text annotation in a PGN game, usually written in braces or as a
  semicolon comment.
- **NAG**: Numeric Annotation Glyph, such as `$1`, used for annotations like
  good move, mistake, or interesting move.
- **Result Marker**: One of `1-0`, `0-1`, `1/2-1/2`, or `*`.
- **FEN-Backed PGN**: A PGN that starts from a non-standard position using
  `[SetUp "1"]` and `[FEN "..."]`.
- **PGN Database**: Text containing one or more PGN games.

## Appendix B: Common Recipes

Consider adding a second appendix with short copy-paste examples:

- Parse one PGN game.
- Parse a PGN database.
- Read tag values.
- Print all SAN moves.
- Convert PGN to concrete coordinate moves.
- Get the final FEN.
- Export a `PGNGame`.
- Export concrete moves as PGN.
- Handle `PGNParsingError`.
- Detect unsupported recursive variations.
