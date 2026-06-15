# ChessCore Testing Strategy

ChessCore tests are treated as a correctness corpus, not just a coverage
percentage. If there is a known chess edge case, notation ambiguity, PGN import
pattern, or regression, the goal is to keep a deterministic local test for it.

Tests must not require network access. Real-world vendored PGN fixtures should
come from Lichess CC0 exports. Sharp rule, notation, parser, and malformed-input
cases should be synthetic or hand-authored.

## Current Coverage Shape

- Rule-engine tests cover 40 known perft positions, focused legal move lists,
  a checked-in `python-chess` oracle corpus with 53 exact legal-move positions
  plus 48 generated move-count/status positions, pawn movement, castling
  restrictions, king safety, pins, checks, double check, discovered-check
  exposure, en passant edge cases, promotion choices, king capture exclusion,
  protected-piece captures, black and white castling stress, checkmate,
  stalemate, promotion-heavy positions, and underpromotion mates.
- Game-state invariant tests cover move counters, en passant lifecycle,
  castling-right mutation, promotion application, game copy independence, and
  board-only position counting. Generated legal-game mutation tests also check
  FEN stability, SAN parse/export stability, halfmove/fullmove counter updates,
  en-passant target updates, king counts, status coherence, and sampled legal
  continuations.
- Game-status tests cover checkmate, stalemate, insufficient material, proven
  dead positions, fifty/seventy-five-move rules, threefold/fivefold repetition,
  repetition-key identity, real-move threshold transitions, draw-claim
  application, replay/reset behavior, status precedence, and a terminal-position
  corpus with promotion mates, underpromotion mates, promoted-piece stalemates,
  promoted-material insufficient-material draws, and blocked dead positions.
  They also cover overlapping automatic draw reasons and insufficient-material
  positions where the side to move is in check.
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
  names, escaped tag strings, empty/brace/semicolon comments, comments around
  result markers, clock/eval/EMT/comment-arrow variants, NAGs, malformed input,
  result mismatches, terminal result/status conflicts, validating `PGNGame`
  export, external results on ongoing positions, 22 checked-in Lichess CC0
  standard-game fixtures, generated legal-game round trips, and long
  deterministic stress games.

## Rule Engine Coverage

Rule-engine coverage currently includes:

- perft baselines for canonical positions, simple endgames, castling,
  en-passant, promotion, checkmate, stalemate, promotion-heavy positions, and
  underpromotion mate positions
- focused legal-move checks for pinned pieces, single check, double check,
  discovered-check exposure, adjacent kings, protected-piece king captures, and
  legal-move terminal positions
- castling rejection without rights, without a rook, with the wrong rook color,
  through check, out of check, onto an attacked square, and with occupied
  queen-side b-files
- castling acceptance when only the rook path is attacked
- en-passant lifecycle, illegal discovered-check en-passant, horizontal skewer
  rejection for both colors, and pawn-check evasion for both colors
- promotion generation for all four piece kinds, with no bare final-rank pawn
  move
- exact legal-move and terminal-state expectations generated from a temporary
  `python-chess` oracle and checked in as Swift fixtures
- generated legal-game mutation checks that replay deterministic games and
  verify invariants after each ply

Perft counts that are not obvious should be cross-checked with an independent
tool, such as a temporary `python-chess` install, before being checked in.

## Game-State Coverage

Game-state invariant coverage currently includes:

- quiet piece moves increment the halfmove clock
- black moves increment the fullmove number
- pawn moves, captures, en passant, and promotion reset the halfmove clock
- en-passant targets are created only by two-square pawn advances
- en-passant targets expire after the next move
- en-passant captures remove the correct pawn
- castling rights are removed after king moves, rook moves, and rook captures on
  original rook squares
- promotion installs the requested piece kind and color
- copied games can be mutated independently
- `positionCounts` tracks board occurrences by `Board`, not full repetition
  state
- generated legal-game mutation tests preserve FEN round-trip stability,
  selected SAN round trips, halfmove/fullmove counters, en-passant targets, king
  counts, status coherence, and sampled legal continuations

## Game Status And Outcome Coverage

Game-status and outcome coverage currently includes:

- ongoing positions, checkmate with winner color, stalemate, `isDraw`,
  `isStalemate`, and `outcome`
- insufficient-material positives for bare kings, king and bishop versus king,
  king and knight versus king, same-color bishop-only positions, and multiple
  same-color bishop shapes for both colors
- insufficient-material negatives for pawns, rooks, queens, bishop and knight,
  two knights, opposing knights, opposite-color bishops, single minor pieces
  plus enemy self-blocking pawns, same-color bishops plus pawns, and mixed
  minor-piece combinations
- `DeadPositionAnalyzer` positives for material-only dead positions and sealed
  immobile pawn-barrier positions with trapped rooks, queens, bishops, and
  mixed sliding pieces
- dead-position symmetry checks under file mirrors and board/color swaps
- dead-position near-misses for open pawn gaps, legal pawn captures, legal
  bishop/rook/queen captures, jumping knights, and attacking material already
  beyond the pawn barrier
- dead-position status/analyzer performance smoke coverage over the
  dead-position corpus plus generated legal middlegame positions
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

## FEN Semantic Validation Coverage

Semantic FEN validation coverage currently includes:

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

Dead-position analysis is intentionally conservative. ChessCore reports dead
positions when they are proven by insufficient mating material, a sealed
immobile pawn barrier, or bounded legal-state reachability. Positions outside
those proven classes remain ongoing rather than risking a false-positive draw.

## FEN And SAN Round-Trip Coverage

Notation round-trip coverage currently includes:

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

When oracle data is useful, check in the generated expectations as Swift test
fixtures instead of making the test suite shell out to Python. The normal test
suite must stay self-contained and network-free.

This audit is based on an inspection of upstream `python-chess` test categories
from commit `8330cfd5dbb9401f0e85be92cf408d6482505642`. The categories are
classified as:

- `Covered`: Current ChessCore tests already exercise the category adequately.
- `Future API`: Useful only after ChessCore exposes more public behavior.
- `Out of scope`: Not a current ChessCore responsibility.

| Area | python-chess coverage signal | ChessCore status | Action | Priority |
| --- | --- | --- | --- | --- |
| Squares | Square construction, parsing, shifts, distance helpers. | Construction, coordinates, and translation are covered. Distance helpers are not public ChessCore API. | Covered | Low |
| Moves | UCI-style move parsing, invalid move text, copy/equality, null/drop moves. | Coordinate parsing, invalid inputs, equality, and promotion spelling are covered. Null moves and drops are not standard ChessCore API. | Covered | Low |
| Pieces | Symbol parsing, equality, hashing. | Piece equality and character mapping are covered. | Covered | Low |
| Board storage | Default/empty boards, get/set/remove pieces, color lookup, piece maps. | Board square/index/coordinate access, copy independence, and enumeration are covered. | Covered | Low |
| FEN syntax | Valid FEN, malformed FEN, counters, en-passant fields, castling fields. | Serialization, malformed fields, generated round trips, adjacent digit rejection, and counter bounds are covered. | Covered | Low |
| FEN semantic status | Bad castling rights, multiple kings, impossible or inconsistent positions. | `PositionValidator` and `FENSerializer.validatedPosition(from:)` cover king counts, pawn ranks, castling rights, en-passant availability, en-passant halfmove-clock consistency, inactive-side check, and multi-issue reporting. Dead-position adjudication is covered separately by `Game.status` and `DeadPositionAnalyzer`. | Covered | Low |
| EPD | EPD parsing, operations, best-move fields. | ChessCore does not support EPD. | Out of scope | Low |
| Legal move generation | Legal move lists, move counts, perft-style fixtures, pseudo-legal distinctions. | Focused legal-move fixtures, 40 perft positions, a 53-position exact legal-move corpus, and 48 generated move-count/status positions created with a temporary `python-chess` oracle are covered, including castling, en-passant, promotion, underpromotion mate, checkmate, stalemate, and generated midgame positions. | Covered | Low |
| Castling | SAN castling, selective castling, missing/invalid rights, rook/king edge cases, Chess960 castling. | Standard castling rights, missing rooks, matching rook color, attacked transit/destination, in-check rejection, b-file occupancy, rook-path attack tolerance, and application are covered. Chess960 is out of scope. | Covered | Low |
| En passant | Legal captures, attackers, impossible/skewered captures, check evasion, pinned-file cases. | En passant lifecycle, SAN/PGN replay, discovered-check rejection, horizontal skewers for both colors, and pawn-check evasion for both colors are covered. | Covered | Low |
| Promotion | Promotion generation, SAN, check/checkmate promotion, underpromotion. | Promotion choices, application, SAN, PGN promotion, promotion captures, underpromotion, and underpromotion mate fixtures are covered. | Covered | Low |
| Attacks and pins | Attack maps, pin direction, pin while in check. | Public legal-move behavior for pins, double check, shielding pieces, and protected-piece king captures is covered. Direct attack-map APIs are not public. | Covered | Low |
| Checkmate and stalemate | Scholar's mate, mate detection, stalemate, legal moves after terminal states. | Check, checkmate, stalemate, terminal legal-move exhaustion, promotion mates, underpromotion mates, and promoted-piece stalemate fixtures are covered. | Covered | Low |
| Draw and outcome rules | Insufficient material, dead positions, threefold/fivefold repetition, fifty/seventy-five move rules, outcome. | `Game.status`, `Game.outcome`, draw claims, claimed draws, automatic draws, dead-position analysis, rules-relevant repetition keys, replay, and reset behavior are covered. `positionCounts` remains board-only by design. | Covered | Low |
| SAN parsing/export | SAN generation, parsing, ambiguous moves, castling, promotion, checkmate, long algebraic notation. | Core SAN, generated round trips, every-legal-move stress round trips, ambiguity, en-passant, promotion, checkmate, optional/decorative check suffixes, coordinate-notation rejection, and missing-disambiguation rejection are covered. Long algebraic notation is not currently accepted as SAN. | Covered | Low |
| PGN basic import/export | Tag roster, setup/FEN, comments, NAGs, headers, no tag roster, empty games, export visitors. | Mainline import/export, sparse and full tag rosters, odd tag names, FEN-backed games, empty games, leading comments, comments, NAGs, invalid NAGs, malformed input, explicit terminal result/status validation, external ongoing-result acceptance, validating `PGNGame` export, 22 checked-in Lichess CC0 fixtures, and round trips are covered. | Covered | Low |
| PGN dialect tolerance | UTF-8 BOM, semicolon comments, odd headers, empty lines, UCI/LAN movetext, ChessBase quirks. | UTF-8 BOM input, compact movetext, `%` escape lines, semicolon comments, empty comments, result-boundary comments, repeated extra tags, escaped strings, odd tag names, empty games, Lichess-style samples, and real Lichess standard-game headers are covered. Non-SAN UCI/LAN movetext and broader ChessBase quirks remain future decisions. | Covered | Low |
| PGN variations | Tree traversal, promote/demote variations, recursive variation handling. | Recursive variations are intentionally rejected by the current PGN implementation and intentionally deferred until ChessCore has a public move-tree API. | Future API | Medium |
| PGN annotation details | Symbolic annotations, eval comments, clock comments, elapsed-move-time fields. | Comments, NAGs including `$0` and leading-zero values, symbolic annotation mapping, Lichess clock/eval comments, elapsed-move-time variants, arrow comments, and colored-square comments are covered. | Covered | Low |
| PGN variants | Chess960, Crazyhouse, antichess, and other variant PGNs. | ChessCore currently targets standard chess. | Out of scope | Low |
| Opening books | Polyglot reader behavior. | ChessCore does not read opening books. | Out of scope | Low |
| Engine protocols | UCI/XBoard engine communication. | Engine integration belongs outside ChessCore; this workspace has separate Stockfish work. | Out of scope | Low |
| Tablebases | Syzygy and Gaviota probing. | ChessCore does not probe endgame tablebases. | Out of scope | Low |
| Rendering | SVG board and piece rendering. | Rendering belongs to ChessUI or app code, not ChessCore. | Out of scope | Low |
| Variants | Suicide, Atomic, Racing Kings, Horde, Three-check, Crazyhouse, Giveaway. | ChessCore currently targets standard chess only. | Out of scope | Low |

### Current API Coverage Summary

Current high-priority API coverage includes:

- a 40-position perft corpus with added castling, en-passant, promotion,
  checkmate, and stalemate positions
- exact legal-move, move-count, and terminal-status expectations from a
  checked-in `python-chess` oracle corpus
- generated legal-game mutation invariants for counters, FEN/SAN stability,
  king counts, status coherence, and sampled legal continuations
- castling edge cases for matching rook color, b-file occupancy, rook-path
  attack tolerance, and in-check rejection
- en-passant horizontal skewer rejection and pawn-check evasion for both colors
- SAN tolerance and rejection boundaries for decorative check suffixes,
  coordinate notation, and missing disambiguation
- PGN sparse tag rosters, UTF-8 BOM input, odd tag names, escaped tag strings,
  empty games, leading comments, comments around result markers, invalid result
  tags, and invalid NAGs
- semantic FEN validation for king counts, pawn ranks, castling rights,
  en-passant targets, and inactive-side check
- game replay/reset and explicit draw-claim behavior
- dead-position analyzer coverage for material-only draws, sealed immobile pawn
  barriers with trapped sliding pieces, symmetry invariants, false-positive
  near-misses, and a status/analyzer performance smoke pass
- PGN result/status conflicts for checkmate, stalemate, insufficient material,
  dead position, seventy-five-move, and fivefold-repetition terminal statuses,
  plus explicit external-result acceptance for ongoing and claimable-draw
  positions

No current-API high-priority rows remain open in the audit matrix. Rows marked
`Future API` or `Out of scope` should stay out of this pass unless the package
direction changes.

## Regression Policy

Every bug fix should include the narrowest permanent regression test that would
have failed before the fix. If a PGN failure is caused by SAN or move legality,
add the lower-level SAN or rules test as well as any PGN-level coverage.
