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

## python-chess Coverage Audit Matrix

`python-chess` is useful as an external coverage checklist and temporary oracle,
but its GPL-licensed tests and fixtures should not be copied into this package.
When a useful category is found, write original Swift tests with synthetic
positions or Lichess CC0 fixtures, and use a temporary `python-chess` install
only to confirm expected values.

This audit is based on an inspection of upstream `python-chess` test categories
from commit `8330cfd5dbb9401f0e85be92cf408d6482505642`. The categories are
classified as:

- `Covered`: Current ChessCore tests already exercise the category adequately.
- `Add next`: Good candidate for the next deterministic ChessCore test pass.
- `Future API`: Useful only after ChessCore exposes more public behavior.
- `Out of scope`: Not a current ChessCore responsibility.

| Area | python-chess coverage signal | ChessCore status | Action | Priority |
| --- | --- | --- | --- | --- |
| Squares | Square construction, parsing, shifts, distance helpers. | Construction, coordinates, and translation are covered. Distance helpers are not public ChessCore API. | Covered | Low |
| Moves | UCI-style move parsing, invalid move text, copy/equality, null/drop moves. | Coordinate parsing, invalid inputs, equality, and promotion spelling are covered. Null moves and drops are not standard ChessCore API. | Covered | Low |
| Pieces | Symbol parsing, equality, hashing. | Piece equality and character mapping are covered. | Covered | Low |
| Board storage | Default/empty boards, get/set/remove pieces, color lookup, piece maps. | Board square/index/coordinate access, copy independence, and enumeration are covered. | Covered | Low |
| FEN syntax | Valid FEN, malformed FEN, counters, en-passant fields, castling fields. | Serialization, malformed fields, generated round trips, adjacent digit rejection, and counter bounds are covered. | Covered | Low |
| FEN semantic status | Bad castling rights, multiple kings, impossible or inconsistent positions. | ChessCore parses FEN syntax but does not expose a full position-status API. | Future API | Medium |
| EPD | EPD parsing, operations, best-move fields. | ChessCore does not support EPD. | Out of scope | Low |
| Legal move generation | Legal move lists, move counts, perft-style fixtures, pseudo-legal distinctions. | Focused legal-move fixtures and 15 perft positions are covered. More standard-position corpus cases remain valuable. | Add next | High |
| Castling | SAN castling, selective castling, missing/invalid rights, rook/king edge cases, Chess960 castling. | Standard castling rights, missing rooks, attacked transit/destination, and application are covered. Chess960 is out of scope. More standard castling regression positions are useful. | Add next | High |
| En passant | Legal captures, attackers, impossible/skewered captures, check evasion, pinned-file cases. | Basic en passant, lifecycle, discovered-check rejection, SAN, and PGN are covered. Skewer/pin/evasion variants should be expanded. | Add next | High |
| Promotion | Promotion generation, SAN, check/checkmate promotion, underpromotion. | Promotion choices, application, SAN, PGN promotion, and underpromotion are covered. More promotion-check and promotion-capture variants are useful. | Add next | Medium |
| Attacks and pins | Attack maps, pin direction, pin while in check. | Public legal-move behavior for pins, double check, shielding pieces, and protected-piece king captures is covered. Direct attack-map APIs are not public. | Add next | Medium |
| Checkmate and stalemate | Scholar's mate, mate detection, stalemate, legal moves after terminal states. | Check, checkmate, and stalemate have focused coverage. A larger terminal-position corpus would be useful. | Add next | Medium |
| Draw and outcome rules | Insufficient material, threefold/fivefold repetition, fifty/seventy-five move rules, outcome. | ChessCore does not expose full game-outcome or draw-claim APIs. Existing `positionCounts` is board-count-only and covered at that level. | Future API | High |
| SAN parsing/export | SAN generation, parsing, ambiguous moves, castling, promotion, checkmate, long algebraic notation. | Core SAN, generated round trips, ambiguity, en-passant, promotion, checkmate, and regression cases are covered. Additional malformed and dialect-tolerance cases are useful. | Add next | High |
| PGN basic import/export | Tag roster, setup/FEN, comments, NAGs, headers, no tag roster, empty games, export visitors. | Mainline import/export, tags, FEN-backed games, comments, NAGs, malformed input, and round trips are covered. More dialect fixtures are useful. | Add next | High |
| PGN dialect tolerance | UTF-8 BOM, semicolon comments, odd headers, empty lines, UCI/LAN movetext, ChessBase quirks. | Compact movetext, escape lines, semicolon comments, and Lichess samples are covered. BOM, empty-line, odd-header, and non-SAN dialect fixtures are candidates. | Add next | Medium |
| PGN variations | Tree traversal, promote/demote variations, recursive variation handling. | Recursive variations are intentionally rejected in the first PGN milestone. | Future API | Medium |
| PGN annotation details | Symbolic annotations, eval comments, clock comments, elapsed-move-time fields. | Comments, NAGs, Lichess clock/eval comments are covered. Symbolic annotation mapping and elapsed-time variants can be deepened. | Add next | Medium |
| PGN variants | Chess960, Crazyhouse, antichess, and other variant PGNs. | ChessCore currently targets standard chess. | Out of scope | Low |
| Opening books | Polyglot reader behavior. | ChessCore does not read opening books. | Out of scope | Low |
| Engine protocols | UCI/XBoard engine communication. | Engine integration belongs outside ChessCore; this workspace has separate Stockfish work. | Out of scope | Low |
| Tablebases | Syzygy and Gaviota probing. | ChessCore does not probe endgame tablebases. | Out of scope | Low |
| Rendering | SVG board and piece rendering. | Rendering belongs to ChessUI or app code, not ChessCore. | Out of scope | Low |
| Variants | Suicide, Atomic, Racing Kings, Horde, Three-check, Crazyhouse, Giveaway. | ChessCore currently targets standard chess only. | Out of scope | Low |

### Recommended Next Test Pass

After this matrix is reviewed, the next implementation pass should focus on the
`Add next` rows with high priority:

- expand standard legal-move/perft corpus with more independently checked
  positions
- add more standard castling regressions around rook/king edge cases
- add en-passant pin, skewer, and check-evasion fixtures
- deepen SAN malformed-input and dialect-tolerance coverage
- deepen PGN dialect coverage for BOM, empty lines, odd headers, and additional
  annotation spellings

Rows marked `Future API` should not be forced into tests until ChessCore exposes
the relevant behavior. Rows marked `Out of scope` should stay out unless the
package direction changes.

## Regression Policy

Every bug fix should include the narrowest permanent regression test that would
have failed before the fix. If a PGN failure is caused by SAN or move legality,
add the lower-level SAN or rules test as well as any PGN-level coverage.
