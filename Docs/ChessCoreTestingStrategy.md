# ChessCore Testing Strategy

ChessCore tests are treated as a correctness corpus, not just a coverage
percentage. If there is a known chess edge case, notation ambiguity, PGN import
pattern, or regression, the goal is to keep a deterministic local test for it.

Tests must not require network access. Real-world vendored PGN fixtures should
come from Lichess CC0 exports. Sharp rule, notation, parser, and malformed-input
cases should be synthetic or hand-authored.

## Current Coverage Shape

- Rule-engine tests cover known perft positions, focused legal move lists, pawn
  movement, castling restrictions, king safety, pins, checks, double check,
  discovered-check exposure, en passant edge cases, promotion choices, king
  capture exclusion, protected-piece captures, black and white castling stress,
  and stalemate.
- Game-state invariant tests cover move counters, en passant lifecycle,
  castling-right mutation, promotion application, game copy independence, and
  board-only position counting.
- FEN tests cover serialization round trips, generated legal-position round
  trips, and malformed input errors.
- SAN tests cover parse/export behavior, checkmate, castling spelling,
  en-passant SAN, pawn-file case sensitivity, generated legal-move round trips,
  targeted ambiguity, promotion, and parser failures.
- PGN tests cover validated import/export, multi-game parsing, FEN-backed games,
  comments, NAGs, malformed input, result mismatches, Lichess CC0 samples,
  generated legal-game round trips, and long deterministic stress games.

## Phase 2 Boundary: Game-State Invariants

The current Phase 2 pass is considered complete for the existing `Game` API
surface when tests verify:

- quiet piece moves increment the halfmove clock
- black moves increment the fullmove number
- pawn moves, captures, en passant, and promotion reset the halfmove clock
- en passant targets are created only by two-square pawn advances
- en passant targets expire after the next move
- en passant captures remove the correct pawn
- castling rights are removed after king moves, rook moves, and rook captures on
  original rook squares
- promotion installs the requested piece kind and color
- copied games can be mutated independently
- `positionCounts` tracks board occurrences by `Board`, not full repetition
  state

If ChessCore later adds explicit game-status APIs for stalemate, insufficient
material, fifty-move rule, or threefold repetition, those APIs should get a new
game-status test pass rather than being folded into this completed boundary.

## Phase 1 Milestone 1 Boundary: Rule Engine Corpus

The first rule-engine corpus milestone is complete when each major bug class has
at least one deterministic local test:

- perft baselines for canonical positions plus simple endgames
- pinned pieces that can only move without exposing their king
- single-check responses by king move, block, or capture
- double-check positions where only king moves are legal
- discovered-check exposure from moving a shielding piece
- en passant rejected when it exposes the king
- en passant target squares rejected when no adjacent pawn can capture
- castling rejected without rights, without a rook, through check, out of check,
  or onto an attacked square
- promotion generation for all four piece kinds, with no bare final-rank pawn
  move
- adjacent kings treated as check
- legal moves never represented as captures of the opposing king
- stalemate represented as no legal moves and not checkmate

This is intentionally a milestone, not the end of rule testing. Future passes
can add more perft positions, more Lichess-derived PGN fixtures, generated
FEN/SAN round trips, and new regression tests for every bug found.

## Phase 1 Milestone 2 Boundary: Rule Engine Corpus

The second rule-engine corpus milestone deepens the first pass without trying to
test every possible chess position. It is complete when tests add:

- a larger perft corpus, currently 15 deterministic positions
- extra castling positions for missing rooks, attacked transit squares, and
  attacked destination squares
- extra pinned-piece cases, including pinned knights and bishops
- extra king-safety cases where a king cannot capture a protected piece
- more simple endgames and promotion/en-passant positions

Perft counts that are not obvious should be cross-checked with an independent
tool, such as a temporary `python-chess` install, before being checked in.

## Phase 3 Boundary: FEN And SAN Round Trips

The first notation round-trip milestone is complete when tests cover:

- deterministic generated legal games whose positions round trip through FEN at
  each ply
- deterministic generated legal games whose selected moves serialize to SAN and
  parse back to the same concrete move
- targeted SAN ambiguity, en-passant check, and promotion-capture checkmate
  cases
- malformed FEN boundary cases such as too many ranks, rank overflow, adjacent
  empty-square digits, invalid castling strings, invalid en-passant squares, and
  counters outside `Int` range

## Regression Policy

Every bug fix should include the narrowest permanent regression test that would
have failed before the fix. If a PGN failure is caused by SAN or move legality,
add the lower-level SAN or rules test as well as any PGN-level coverage.
