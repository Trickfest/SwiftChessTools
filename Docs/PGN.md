# PGN Support

PGN support lives in `ChessCore`, not `ChessUI`. The parser models game records
and validates moves; UI layers can decide later how much of a game record to
display.

## Current Support

- Single-game parsing with `PGNSerializer.game(from:)`.
- Multi-game database parsing with `PGNSerializer.games(from:)`.
- Standard tag pairs and extra tags, preserving source order.
- Mainline SAN replay through `SANSerializer` and `Game`.
- Concrete `Move` values, canonical SAN, source SAN, move number, side, and ply
  on each `PGNMoveRecord`.
- `PGNGame.finalStatus`, `finalOutcome`, and result/status consistency helpers.
- Results: `1-0`, `0-1`, `1/2-1/2`, and `*`.
- Result/status validation for terminal final positions: checkmate must match
  the winning side, and automatic draws, including dead positions, must use
  `1/2-1/2`.
- FEN-backed games with `[SetUp "1"]` and `[FEN "..."]`.
- Escaped tag strings, brace comments, empty comments, semicolon comments,
  comments around result markers, `%` escape lines, Lichess clock/eval/elapsed
  move time comments, arrow/square annotation comments, and NAGs.
- Repeated nonstandard tags are preserved in source order; tag lookup returns
  the first matching tag value.
- Deterministic PGN export with the seven tag roster first.
- Validating `PGNGame` export with `try PGNSerializer().pgn(from:)`; manually
  constructed `PGNGame` values must replay to their stored final position,
  final status, SAN, move numbers, side-to-move data, and result.

Ongoing final positions may still carry decisive or drawn results because real
PGNs can end by resignation, timeout, adjudication, or draw agreement before the
board position itself is terminal.

ChessCore only rejects result contradictions it can prove. Claimable draws, such
as fifty-move or threefold-repetition claims, remain ongoing until claimed and
therefore may still be exported or imported with any PGN result marker.

## Future Release API

Recursive annotation variations are lexed and reported with a specific
`PGNParsingError.unsupportedRecursiveVariation` error. Full variation modeling
is intentionally deferred until a future release. It should be added with a
public move-tree model that can represent variation trees cleanly instead of
flattening them.

## Fixture Policy

Use synthetic PGNs for edge cases and parser failures. Use Lichess standard
database samples for checked-in real-world corpus coverage because Lichess
publishes those exports under Creative Commons CC0. Avoid vendoring PGNs from
TWIC, commercial databases, or tournament sites unless redistribution rights are
explicit and compatible with this package.

Checked-in Lichess fixtures should stay small, static, and offline. Fetch from
Lichess only when refreshing the corpus, then commit the selected PGN text so
normal tests never require network access.

## Learning Path

For a ChessCore-first walkthrough that covers PGN together with FEN validation,
SAN, game status, and dead-position behavior, see
[ChessCoreTutorial.md](ChessCoreTutorial.md).

For a runnable command-line example that parses PGN, prints validated move
records, reports final status, exports normalized PGN, and demonstrates FEN
validation, see [Examples/ChessCoreRecipes](../Examples/ChessCoreRecipes).
