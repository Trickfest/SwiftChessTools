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
- Added PGN coverage for Lichess-style comments, a Lichess CC0 sample, result
  mismatches, malformed syntax, invalid SAN, FEN-backed games, castling,
  promotion, underpromotion, en passant, disambiguation, and export round trips.
- Expanded PGN coverage with a Lichess CC0 mini-corpus, deterministic generated
  legal-game round trips, 10 long generated stress games, compact movetext and
  escape-line tolerance, and additional SAN ambiguity fixtures.

### Changed

- Replaced the bundled legacy piece PNGs with self-contained prefixed piece
  asset families that can be added or removed one set at a time.
- Marked `PieceColor`, `PieceKind`, `Square`, and `Move` as `Sendable` so they
  can be used in concurrent, value-semantic ChessUI display state.
- Marked `Board`, `Bitboards`, `Piece`, and `Position` as `Sendable` so
  validated PGN game records can remain concurrency-safe value types.

### Fixed

- Fixed SAN serialization for en-passant captures so PGN import/export can
  round trip en-passant SAN such as `exd6`.
- Fixed SAN parsing normalization so pawn-file SAN such as `bxc5` remains
  distinct from piece SAN such as `Bxc5`.

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
