# ChessCore Glossary Outline

This is a planning outline for a future ChessCore-only tutorial. The glossary
probably belongs near the end of that tutorial as an appendix, after readers
have already seen the concepts in context.

## Suggested Placement

Add this as `Appendix A: ChessCore Glossary`.

The main tutorial should stay example-driven. The glossary should be a reference
section for developers who want to confirm terminology after working through
FEN, moves, SAN, and PGN examples.

## Package And API Terms

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

## Chess And Rules Terms

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

## Notation Terms

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

## PGN Terms

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

## Optional Appendix B: Common Recipes

Consider adding a second appendix after the glossary with copy-paste examples:

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
