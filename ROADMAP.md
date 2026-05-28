# Roadmap

## Phase 1: Migration

- Create `ChessCore` from the core chess model, rules, and notation code.
- Create `ChessUI` from reusable SwiftUI board UI code.
- Preserve behavior and type names unless compilation requires a narrow change.
- Keep notation and serialization in `ChessCore` for now.

## Phase 2: Test Strengthening

Strengthen coverage around rules, notation, move legality, UI behavior, and edge
cases before reshaping APIs.

## Phase 3: Public API Cleanup

Clean up public API naming once the migrated behavior is stable. Possible future
names include `ChessBoard`, `ChessSquare`, `ChessPiece`, `ChessMove`,
`ChessPosition`, `ChessGame`, `FENParser`, `FENFormatter`, `SANParser`,
`SANFormatter`, and `ChessBoardView`.

## Phase 4: Notation Boundary

Consider extracting notation into a separate target, likely `ChessNotation`,
after boundaries are clear. Keep FEN/SAN/PGN/UCI-related functionality there if
it grows.

## Phase 5: Separate Notation Package

Only consider a separate notation repo/package if multiple unrelated packages
need it independently.

## Optional Future Targets

Potential future targets include `ChessEngine`, `ChessPGN`, `ChessOpeningBook`,
`ChessAnalysis`, or `ChessTraining`. These are intentionally out of scope for
phase one.
