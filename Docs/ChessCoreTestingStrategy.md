# ChessCore Testing Strategy

ChessCore tests are treated as a correctness corpus, not just a coverage
percentage. If there is a known chess edge case, notation ambiguity, PGN import
pattern, or regression, the goal is to keep a deterministic local test for it.

Tests must not require network access. Real-world vendored PGN fixtures should
come from Lichess CC0 exports. Sharp rule, notation, parser, and malformed-input
cases should be synthetic or hand-authored.

## Current Coverage Shape

- Rule-engine tests cover 40 known perft positions, focused legal move lists,
  pawn movement, castling restrictions, king safety, pins, checks, double check,
  discovered-check exposure, en passant edge cases, promotion choices, king
  capture exclusion, protected-piece captures, black and white castling stress,
  checkmate, stalemate, promotion-heavy positions, and underpromotion mates.
- Game-state invariant tests cover move counters, en passant lifecycle,
  castling-right mutation, promotion application, game copy independence, and
  board-only position counting.
- Game-status tests cover checkmate, stalemate, insufficient material,
  fifty/seventy-five-move rules, threefold/fivefold repetition, repetition-key
  identity, real-move threshold transitions, draw-claim application,
  replay/reset behavior, status precedence, and a terminal-position corpus with
  promotion mates, underpromotion mates, promoted-piece stalemates, and
  promoted-material insufficient-material draws. They also cover overlapping
  automatic draw reasons and insufficient-material positions where the side to
  move is in check.
- FEN tests cover serialization round trips, generated legal-position round
  trips, malformed input errors, and strict semantic position validation,
  including multi-issue reporting, castling-right piece mismatches, en-passant
  target and halfmove-clock consistency, and white/black en-passant exposure
  cases.
- SAN tests cover parse/export behavior, checkmate, castling spelling,
  en-passant SAN, pawn-file case sensitivity, generated legal-move round trips,
  targeted three-or-more-piece ambiguity, optional/decorative check suffixes,
  promotion, underpromotion mate, castling checks for both colors, and parser
  failures. Targeted stress fixtures also round-trip every legal move through
  SAN in ambiguity-heavy, en-passant, castling, and promotion-heavy positions.
- PGN tests cover validated import/export, multi-game parsing, FEN-backed games,
  UTF-8 BOM input, `%` escape lines, sparse tag rosters, odd and repeated tag
  names, empty/brace/semicolon comments, clock/eval/EMT comment variants, NAGs,
  malformed input, result mismatches, terminal result/status conflicts, Lichess
  CC0 samples, generated legal-game round trips, and long deterministic stress
  games.

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

Game status and outcome behavior is covered by a separate boundary below.

## Game Status And Outcome Boundary

The current game-status pass is complete for the existing `Game` API surface
when tests verify:

- ongoing positions, checkmate with winner color, stalemate, `isDraw`,
  `isStalemate`, and `outcome`
- insufficient-material positives for bare kings, king and bishop versus king,
  king and knight versus king, same-color bishop-only positions, and
  promotion-like multiple-bishop positions
- insufficient-material negatives for pawns, rooks, queens, bishop and knight,
  two knights, opposing knights, opposite-color bishops, and mixed minor-piece
  combinations
- fifty-move draw claims at 100 halfmoves and seventy-five-move automatic draws
  at 150 halfmoves
- quiet moves that cross fifty/seventy-five-move thresholds, plus pawn moves
  and captures that reset draw pressure
- threefold draw claims and fivefold automatic draws for the current repetition
  key, including a game-like knight repetition from the standard starting
  position
- repetition keys distinguish side to move and castling rights
- repetition keys ignore irrelevant en-passant target fields but include legal
  en-passant availability
- repetition keys ignore en-passant target fields when an adjacent pawn exists
  but the capture is illegal because it exposes the king
- status precedence for terminal positions, insufficient material, automatic
  draws, and claimable draw combinations
- successful fifty-move and threefold claims, unavailable claim failures, claim
  clearing after a move, and claim preservation when copying a game
- `Game.replay(initialPosition:moves:)` rebuilding history, counters, and
  repetition state from legal moves
- `Game.replay(initialPosition:moves:)` reporting the illegal ply for invalid
  move lists
- `Game.reset(to:moveHistory:)` replacing position/history and clearing derived
  state
- board-only `positionCounts` remain separate from rules-relevant
  `repetitionCounts`
- copied games preserve repetition state but mutate independently

## FEN Semantic Validation Boundary

The semantic FEN validation pass is complete for the current public API when
tests verify:

- `FENSerializer.position(from:)` remains syntax-only
- `FENSerializer.validatedPosition(from:)` returns valid playable positions
- missing kings and multiple kings are reported
- pawns on the first or eighth rank are reported
- castling rights require the matching king and rook on their starting squares
- en-passant targets require an empty target square, the capturable pawn, and at
  least one legal en-passant capture
- en-passant targets require a zero halfmove clock because the previous move
  must have been a pawn move
- en-passant targets are rejected when the apparent capture would expose the
  moving side's king
- the inactive side's king may not already be in check
- independent semantic issues are reported together instead of stopping after
  the first issue

Full FIDE dead-position reachability for blocked structures remains future work
and is intentionally not part of this boundary.

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

- a larger perft corpus, currently 40 deterministic positions
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
- every legal move in targeted high-stress positions round trips through SAN
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
| FEN semantic status | Bad castling rights, multiple kings, impossible or inconsistent positions. | `PositionValidator` and `FENSerializer.validatedPosition(from:)` cover king counts, pawn ranks, castling rights, en-passant availability, en-passant halfmove-clock consistency, inactive-side check, and multi-issue reporting. Full dead-position reachability remains future work. | Covered | Low |
| EPD | EPD parsing, operations, best-move fields. | ChessCore does not support EPD. | Out of scope | Low |
| Legal move generation | Legal move lists, move counts, perft-style fixtures, pseudo-legal distinctions. | Focused legal-move fixtures and 40 perft positions are covered, including more castling, en-passant, promotion, underpromotion mate, checkmate, and stalemate positions. | Covered | Low |
| Castling | SAN castling, selective castling, missing/invalid rights, rook/king edge cases, Chess960 castling. | Standard castling rights, missing rooks, matching rook color, attacked transit/destination, in-check rejection, b-file occupancy, rook-path attack tolerance, and application are covered. Chess960 is out of scope. | Covered | Low |
| En passant | Legal captures, attackers, impossible/skewered captures, check evasion, pinned-file cases. | En passant lifecycle, SAN/PGN replay, discovered-check rejection, horizontal skewers for both colors, and pawn-check evasion for both colors are covered. | Covered | Low |
| Promotion | Promotion generation, SAN, check/checkmate promotion, underpromotion. | Promotion choices, application, SAN, PGN promotion, promotion captures, underpromotion, and underpromotion mate fixtures are covered. | Covered | Low |
| Attacks and pins | Attack maps, pin direction, pin while in check. | Public legal-move behavior for pins, double check, shielding pieces, and protected-piece king captures is covered. Direct attack-map APIs are not public. | Add next | Medium |
| Checkmate and stalemate | Scholar's mate, mate detection, stalemate, legal moves after terminal states. | Check, checkmate, stalemate, terminal legal-move exhaustion, promotion mates, underpromotion mates, and promoted-piece stalemate fixtures are covered. | Covered | Low |
| Draw and outcome rules | Insufficient material, threefold/fivefold repetition, fifty/seventy-five move rules, outcome. | `Game.status`, `Game.outcome`, draw claims, claimed draws, automatic draws, rules-relevant repetition keys, replay, and reset behavior are covered. `positionCounts` remains board-only by design. | Covered | Low |
| SAN parsing/export | SAN generation, parsing, ambiguous moves, castling, promotion, checkmate, long algebraic notation. | Core SAN, generated round trips, every-legal-move stress round trips, ambiguity, en-passant, promotion, checkmate, optional/decorative check suffixes, coordinate-notation rejection, and missing-disambiguation rejection are covered. Long algebraic notation is not currently accepted as SAN. | Covered | Low |
| PGN basic import/export | Tag roster, setup/FEN, comments, NAGs, headers, no tag roster, empty games, export visitors. | Mainline import/export, sparse and full tag rosters, odd tag names, FEN-backed games, empty games, leading comments, comments, NAGs, invalid NAGs, malformed input, terminal result/status validation, and round trips are covered. | Covered | Low |
| PGN dialect tolerance | UTF-8 BOM, semicolon comments, odd headers, empty lines, UCI/LAN movetext, ChessBase quirks. | UTF-8 BOM input, compact movetext, `%` escape lines, semicolon comments, empty comments, repeated extra tags, odd tag names, empty games, and Lichess-style samples are covered. Non-SAN UCI/LAN movetext and broader ChessBase quirks remain future decisions. | Covered | Low |
| PGN variations | Tree traversal, promote/demote variations, recursive variation handling. | Recursive variations are intentionally rejected in the first PGN milestone. | Future API | Medium |
| PGN annotation details | Symbolic annotations, eval comments, clock comments, elapsed-move-time fields. | Comments, NAGs, symbolic annotation mapping, Lichess clock/eval comments, and elapsed-move-time variants are covered. | Covered | Low |
| PGN variants | Chess960, Crazyhouse, antichess, and other variant PGNs. | ChessCore currently targets standard chess. | Out of scope | Low |
| Opening books | Polyglot reader behavior. | ChessCore does not read opening books. | Out of scope | Low |
| Engine protocols | UCI/XBoard engine communication. | Engine integration belongs outside ChessCore; this workspace has separate Stockfish work. | Out of scope | Low |
| Tablebases | Syzygy and Gaviota probing. | ChessCore does not probe endgame tablebases. | Out of scope | Low |
| Rendering | SVG board and piece rendering. | Rendering belongs to ChessUI or app code, not ChessCore. | Out of scope | Low |
| Variants | Suicide, Atomic, Racing Kings, Horde, Three-check, Crazyhouse, Giveaway. | ChessCore currently targets standard chess only. | Out of scope | Low |

### High-Priority Current-API Pass Boundary

The high-priority current-API audit pass is complete when tests cover:

- a 40-position perft corpus with added castling, en-passant, promotion,
  checkmate, and stalemate positions
- castling edge cases for matching rook color, b-file occupancy, rook-path
  attack tolerance, and in-check rejection
- en-passant horizontal skewer rejection and pawn-check evasion for both colors
- SAN tolerance and rejection boundaries for decorative check suffixes,
  coordinate notation, and missing disambiguation
- PGN sparse tag rosters, UTF-8 BOM input, odd tag names, empty games, leading
  comments, invalid result tags, and invalid NAGs
- semantic FEN validation for king counts, pawn ranks, castling rights,
  en-passant targets, and inactive-side check
- game replay/reset and explicit draw-claim behavior
- PGN result/status conflicts for terminal checkmate and automatic draw
  positions

No current-API high-priority rows remain open in the audit matrix. Rows marked
`Future API` or `Out of scope` should stay out of this pass unless the package
direction changes.

## Regression Policy

Every bug fix should include the narrowest permanent regression test that would
have failed before the fix. If a PGN failure is caused by SAN or move legality,
add the lower-level SAN or rules test as well as any PGN-level coverage.
