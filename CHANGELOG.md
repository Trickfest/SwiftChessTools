# Changelog

All notable changes to SwiftChessTools should be documented in this file.

Entries stay under `Unreleased` until the repo is tagged or otherwise prepared
for a release.

## Unreleased

### Added

- Added ChessUI move feedback for position updates made with `setFen(_:lan:)`:
  pieces now animate from the source square to the destination square, and the
  most recent move's source and destination squares remain highlighted.
- Added public ChessUI configuration for move feedback:
  `moveAnimationDuration`, `showLastMoveHighlight`, `lastMoveHighlight`,
  `lastMoveSquares`, and `clearLastMoveHighlight()`.
- Added ChessUI smoke tests covering move-feedback state and direct FEN
  assignment behavior.

### Changed

- Increased the default ChessUI move animation duration to `0.45` seconds so
  longer piece moves are easier to see.
- Direct assignment to `ChessboardModel.fen` now clears move-specific animation
  and highlight state because a raw FEN string does not identify the previous
  source square.

### Fixed

- Fixed move animation startup so SwiftUI renders the piece at the source square
  before animating it to the destination, avoiding a visual snap.
- Changed ChessUI piece rendering to use SwiftUI package asset images, avoiding
  `AsyncImage` races without introducing UIKit or AppKit dependencies.
