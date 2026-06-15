# Changelog

All notable changes to SwiftChessTools should be documented in this file.

Entries stay under `Unreleased` until they are assigned to a planned or tagged
release. Replace `TBD` with the release date when a release is tagged.

## Unreleased

### Added

- Added selectable built-in ChessUI piece sets: Sashite Merida,
  Art Deco Monochrome, Brutalist Monochrome, Origami Monochrome,
  Circuit Board Monochrome, Blueprint Monochrome, and Sports Monochrome.
- Added `ChessPieceSet.availableSets` so apps can query the bundled piece-set
  registry at runtime.
- Added selectable built-in ChessUI board themes: Classic Green, Warm Walnut,
  Blue Study, Marble, Blueprint, Art Deco Monochrome, Circuit Board, and Sports
  Court.
- Added `ChessBoardTheme.availableThemes` so apps can query the bundled board
  theme registry at runtime.
- Added `ChessPieceSet` asset resolution coverage, per-piece-set ChessUI
  snapshots, per-board-theme ChessUI snapshots, and ChessWorkbench UI coverage
  for selecting each built-in set and theme.
- Added `ChessEvaluation`, `ChessEvaluationBar`, and normalized display-state
  helpers so apps can render caller-supplied centipawn, mate, or unavailable
  evaluation states without wiring an engine into ChessUI.
- Added ChessUI evaluation-bar mapping tests and ChessWorkbench UI coverage for
  evaluation samples, placement, orientation, White-side selection, label
  visibility, and centipawn scale controls.
- Added `ChessMoveRecord`, `ChessMoveRecordBuilder`, and `ChessMoveListView`
  so apps can render scrollable caller-supplied SAN move records without adding
  PGN parsing or game-history ownership to ChessUI.
- Added move-record builder tests, ChessUI move-list render coverage, and
  ChessWorkbench UI coverage for move-list updates after legal board moves.
- Added horizontal `ChessMoveListView` layout support and ChessWorkbench
  controls/tests for switching between vertical and horizontal move-list
  presentations.
- Added consumer-controlled `ChessMoveListView` scroll indicator visibility and
  a ChessWorkbench toggle for showing or hiding move-list scroll bars.
- Added `PGNSerializer`, `PGNGame`, `PGNTagPair`, `PGNResult`,
  `PGNMoveRecord`, `PGNNumericAnnotationGlyph`, and typed PGN parser/exporter
  errors to `ChessCore`.
- Added validated mainline PGN parsing, multi-game database parsing,
  FEN-backed PGN support, comment and NAG preservation, and deterministic PGN
  export.
- Added `PGNGame.finalStatus`, `finalOutcome`, result/status consistency
  helpers, and validating `PGNGame` export so manually constructed game records
  must replay to their stored final position, final status, and result.
- Added PGN coverage for Lichess-style comments, a Lichess CC0 sample, result
  mismatches, malformed syntax, invalid SAN, FEN-backed games, castling,
  promotion, underpromotion, en passant, disambiguation, and export round trips.
- Expanded PGN coverage with a Lichess CC0 mini-corpus, deterministic generated
  legal-game round trips, 10 long generated stress games, compact movetext and
  escape-line tolerance, and additional SAN ambiguity fixtures.
- Expanded ChessCore rule-engine and game-state invariant coverage for pins,
  single and double check, king exposure, castling restrictions, en passant,
  promotion, stalemate, move counters, castling rights, game copies, and
  board-only position counts.
- Added `Docs/ChessCoreTestingStrategy.md` to document the ChessCore
  correctness-corpus approach and current rule/game-state coverage boundaries.
- Expanded the ChessCore rule-engine corpus with additional perft positions,
  castling stress cases, pinned-piece fixtures, protected-piece captures,
  promotion, en-passant, and simple endgame coverage.
- Added deterministic FEN and SAN notation round-trip tests over generated legal
  games plus targeted SAN ambiguity, en-passant check, and promotion-checkmate
  fixtures.
- Added `Docs/ChessCoreTutorial.md` and `Docs/ChessCoreGlossary.md` as
  ChessCore-only learning references for rules, notation, PGN, and terminology.
- Added a `python-chess` coverage audit matrix to the ChessCore testing
  strategy to guide future original Swift test expansion without adding a
  dependency or copying GPL-licensed fixtures.
- Expanded high-priority ChessCore audit coverage for legal move generation,
  castling, en passant, SAN parsing, and PGN import/export edge cases, including
  a 27-position perft corpus.
- Added `GameStatus`, `GameOutcome`, `GameDrawReason`, `GameDrawClaim`, and
  `GameRepetitionKey` so ChessCore consumers can inspect checkmate, stalemate,
  insufficient material, dead positions, fifty/seventy-five-move rules, and
  threefold/fivefold repetition state.
- Added hardened GameStatus coverage for material edge cases, real-move draw
  threshold transitions, halfmove resets, illegal en-passant repetition keys,
  status precedence, and game-like knight repetitions.
- Added `Game.replay(initialPosition:moves:)`, `Game.reset(to:moveHistory:)`,
  `Game.claimDraw(_:)`, `GameReplayError`, and `GameDrawClaimError` so
  consumers can rebuild game state from concrete moves, reuse game objects, and
  model explicit fifty-move or threefold draw claims.
- Added `PositionValidator`, `PositionValidationIssue`,
  `PositionValidationError`, and `FENSerializer.validatedPosition(from:)` for
  strict semantic validation of syntactically parsed FEN positions.
- Added PGN result/status validation so terminal checkmate and automatic-draw
  final positions reject incompatible PGN result markers during import and
  export.
- Added coverage for game replay/reset, explicit draw claims, semantic FEN
  validation, PGN terminal result/status conflicts, and result-aware generated
  PGN stress games.
- Expanded ChessCore hardening coverage for PGN dialect imports, terminal
  positions, semantic FEN validation, SAN stress cases, and a 40-position perft
  corpus cross-checked with a temporary `python-chess` oracle.
- Added a second ChessCore hardening layer for multi-issue FEN semantic
  validation, every-legal-move SAN stress round trips, automatic draw precedence
  overlaps, checked insufficient-material positions, and generated game-status
  invariants.
- Added oracle-backed ChessCore hardening with a checked-in `python-chess`
  corpus covering 53 exact legal-move/status positions and 48 generated
  move-count/status positions, generated legal-game mutation invariants, and an
  expanded PGN dialect corpus for escaped tags, result boundary comments,
  semicolon/empty comments, Lichess clock/eval/EMT fields, arrow/square
  annotations, and repeated tags.
- Added `DeadPositionAnalyzer` plus ChessCore status/PGN coverage for material
  dead positions, sealed immobile pawn-barrier dead positions, symmetry
  invariants, false-positive guards, and dead-position result validation.
- Expanded dead-position hardening with additional material-theory fixtures,
  trapped-piece pawn-barrier fixtures, capture-based near-miss fixtures, and a
  status/analyzer performance smoke test.

### Changed

- Changed `PGNSerializer.pgn(from:)` to validate the supplied `PGNGame` and
  throw `PGNSerializationError` when the model is internally inconsistent or
  its result conflicts with a terminal final status.
- Replaced the bundled legacy piece PNGs with self-contained prefixed piece
  asset families that can be added or removed one set at a time.
- Marked `PieceColor`, `PieceKind`, `Square`, and `Move` as `Sendable` so they
  can be used in concurrent, value-semantic ChessUI display state.
- Marked `Board`, `Bitboards`, `Piece`, and `Position` as `Sendable` so
  validated PGN game records can remain concurrency-safe value types.
- Made `Game.position` publicly read-only; use `Game.apply(move:)`,
  `Game.replay(initialPosition:moves:)`, or `Game.reset(to:moveHistory:)` to
  change game state.
- Clarified that `Game(position:moveHistory:)` stores move history as metadata
  only and does not replay moves or rebuild counters/repetition state.
- Changed `Game.drawClaims` so terminal positions and already-claimed draws no
  longer expose claimable draw rules.

### Fixed

- Fixed SAN serialization for en-passant captures so PGN import/export can
  round trip en-passant SAN such as `exd6`.
- Fixed SAN parsing normalization so pawn-file SAN such as `bxc5` remains
  distinct from piece SAN such as `Bxc5`.
- Fixed legal move generation so king captures are never emitted as legal moves.
- Fixed check detection so adjacent kings count as attacks.
- Fixed castling generation so castling rights alone are not enough when the
  corresponding rook is missing from its starting square.
- Fixed FEN parsing so adjacent empty-square digit runs such as `11` are
  rejected instead of accepted as valid piece placement.
- Fixed PGN parsing so a UTF-8 byte-order marker at the start of input is
  ignored instead of being treated as movetext.
- Fixed repetition tracking for draw rules by adding a rules-relevant
  repetition key that includes board layout, side to move, castling rights, and
  legal en-passant availability.
- Fixed draw-claim precedence so checkmate, stalemate, insufficient material,
  seventy-five-move automatic draws, and fivefold repetition remain authoritative
  over claimable draw rules.
- Fixed semantic FEN validation so an en-passant target with a nonzero halfmove
  clock is rejected as internally inconsistent.

## 1.0.0 - TBD

Initial public-ready release.

### Added

- Added public parser error types for malformed input:
  `FENParsingError`, `SANParsingError`, and `MoveParsingError`.
- Added ChessUI move feedback for position updates made with
  `setFEN(_:animatedMove:)`:
  pieces now animate from the source square to the destination square, and the
  most recent move's source and destination squares remain highlighted.
- Added public ChessUI configuration for move feedback:
  `moveAnimationDuration`, `showsLastMoveHighlight`, `lastMoveHighlightColor`,
  `lastMoveSquares`, and `clearLastMoveHighlight()`.
- Added ChessUI smoke tests covering move-feedback state and direct FEN
  assignment behavior.
- Added ChessCore perft tests for standard reference positions, broader SAN
  parsing coverage, and focused legal-move coverage around en-passant targets.
- Added ChessUI model tests for legal-move highlighting, hints, promotion
  state, and board configuration defaults.
- Added ChessUI snapshot tests with checked-in references for board
  orientation, selection, last-move highlighting, promotion UI, and color
  schemes.
- Added a simulator-backed ChessUI XCUITest harness that drives the real board
  through tap moves, drag moves, invalid moves, promotion, black perspective,
  legal-move indicators, and last-move highlights.
- Added the macOS `ChessWorkbench` manual workbench under
  `Examples/ChessWorkbench` so package-level UI and rules checks live with
  `SwiftChessTools`.
- Added a macOS `ChessWorkbenchUITests` XCUITest suite that drives the example
  app through board rendering, legal and invalid moves, full-square destination
  taps, FEN updates, markers, promotion UI, copy feedback, and reset behavior.
- Added `Scripts/test-all.sh` to run the SwiftPM tests, the simulator-backed
  `ChessUIHarness` UI tests, and the macOS `ChessWorkbench` UI tests together.
- Added GitHub Actions CI for the SwiftPM test suite.
- Added public readiness docs, contribution guidance, issue templates, and a
  README screenshot.

### Changed

- `FENSerializer.position(from:)`, `SANSerializer.move(for:in:)`,
  `Move.init(string:)`, and `Game.apply(move:)` for coordinate strings now
  report malformed input with thrown errors instead of trapping.
- Renamed the primary ChessUI public board API to `ChessBoardView`,
  `ChessBoardModel`, and the current board styling types.
- Renamed inherited ChessCore APIs and internals for the current package shape,
  including `FENSerializer`, `SANSerializer`, `Game.apply(move:)`, and the
  move-generation types.
- Renamed the promotion picker dismissal API to `dismissPromotionPicker()`.
- Increased the default ChessUI move animation duration to `0.45` seconds so
  longer piece moves are easier to see.
- Direct assignment to `ChessBoardModel.fen` now clears move-specific animation
  and highlight state because a raw FEN string does not identify the previous
  source square.
- `ChessBoardModel` now records invalid FEN input in `fenError`; failed FEN
  updates leave the current board unchanged.

### Fixed

- Fixed public parser failure behavior so malformed FEN, SAN, and coordinate
  moves are handled as recoverable errors.
- Fixed move animation startup so SwiftUI renders the piece at the source square
  before animating it to the destination, avoiding a visual snap.
- Changed ChessUI piece rendering to use SwiftUI package asset images, avoiding
  `AsyncImage` races without introducing UIKit or AppKit dependencies.
- Fixed legal-move filtering so a non-pawn move to the current en-passant target
  square is not simulated as an en-passant capture.
- Fixed ChessUI tap hit testing so the full board square is interactive when
  selecting pieces or clicking destination squares.
