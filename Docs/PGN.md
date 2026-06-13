# PGN Support

PGN support lives in `ChessCore`, not `ChessUI`. The parser models game records
and validates moves; UI layers can decide later how much of a game record to
display.

## Supported In The First Pass

- Single-game parsing with `PGNSerializer.game(from:)`.
- Multi-game database parsing with `PGNSerializer.games(from:)`.
- Standard tag pairs and extra tags, preserving source order.
- Mainline SAN replay through `SANSerializer` and `Game`.
- Concrete `Move` values, canonical SAN, source SAN, move number, side, and ply
  on each `PGNMoveRecord`.
- Results: `1-0`, `0-1`, `1/2-1/2`, and `*`.
- FEN-backed games with `[SetUp "1"]` and `[FEN "..."]`.
- Brace comments, semicolon comments, Lichess clock/eval comments, and NAGs.
- Deterministic PGN export with the seven tag roster first.

## Deferred

Recursive annotation variations are lexed and reported with a specific
`PGNParsingError.unsupportedRecursiveVariation` error. Full variation modeling
should be added as a separate milestone so the public model can represent
variation trees cleanly instead of flattening them.

## Fixture Policy

Use synthetic PGNs for edge cases and parser failures. Use Lichess standard
database samples for checked-in real-world corpus coverage because Lichess
publishes those exports under Creative Commons CC0. Avoid vendoring PGNs from
TWIC, commercial databases, or tournament sites unless redistribution rights are
explicit and compatible with this package.
