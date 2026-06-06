# Contributing

Thanks for considering a contribution to SwiftChessTools.

## Project Scope

SwiftChessTools is a Swift package for reusable chess rules, notation, and
SwiftUI board UI. Keep contributions focused on `ChessCore`, `ChessUI`, tests,
examples, or package documentation.

This package does not include a chess engine. Stockfish integration lives in the
separate GPL-licensed `StockfishEmbedded` sibling project and should not be
copied into this MIT-licensed package.

## Local Setup

Use Xcode with Swift tools 6.1 or newer. From the repository root:

```sh
swift test
```

For the broader local validation pass:

```sh
Scripts/test-all.sh
```

`Scripts/test-all.sh` runs the SwiftPM suite, the simulator-backed
`ChessUIHarness` UI tests, and the macOS `ChessWorkbench` UI tests.

## Pull Requests

- Keep changes scoped and describe the user-visible behavior they affect.
- Add or update tests for rules behavior, parser behavior, UI state, or public
  API changes.
- Update `CHANGELOG.md` for user-facing, API, behavior, dependency, or migration
  changes.
- Update README or example code when public APIs or expected usage changes.
- Do not commit generated build products, DerivedData, downloaded engine files,
  `.build`, `.swiftpm`, or Xcode user state.

## Style

Prefer the existing Swift style in the surrounding file. Use clear names, small
types, and public doc comments for public APIs. Parser APIs that accept
user-provided strings should report malformed input with recoverable errors
rather than traps.

## Reporting Issues

Use the GitHub issue templates for bugs and feature requests. Include the
platform, Xcode version, package version or commit, and the smallest example
that reproduces the behavior.
