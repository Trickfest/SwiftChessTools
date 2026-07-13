# Contributing

Thanks for considering a contribution to SwiftChessTools.

## Project Scope

SwiftChessTools is a Swift package for reusable chess rules, notation, UCI
command/parsing helpers, and SwiftUI board UI. Keep contributions focused on
`ChessCore`, `ChessUI`, `ChessUCI`, tests, examples, or package documentation.

This package does not include a chess engine. Stockfish integration lives in the
separate GPL-licensed `StockfishEmbedded` project and should not be copied into
this MIT-licensed package.

## Local Setup

Use Xcode with Swift tools 6.2 or newer. From the repository root:

```sh
swift test
```

For the broader local validation pass:

```sh
Scripts/test-all.sh
```

`Scripts/test-all.sh` runs the SwiftPM suite, a Release build, the ChessCore
recipe, public-API compatibility against the latest available tag, the
simulator-backed `ChessUIHarness` UI tests, and the macOS `ChessWorkbench` UI
tests. A checkout without Git tags skips only the API comparison.

GitHub Actions CI is manual-only and optional. It does not run on pushes or
pull requests, and its completion or success is not required for pull-request
acceptance. Local validation remains expected. Maintainers can explicitly
dispatch the hosted checks for a branch or tag already on GitHub with:

```sh
Scripts/run-github-ci.sh [ref]
```

The dispatcher never commits or pushes local changes. The workflow calls
`Scripts/github-ci.sh`; it does not replace the full local UI coverage in
`Scripts/test-all.sh`.

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
