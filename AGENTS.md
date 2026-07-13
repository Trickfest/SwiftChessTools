# SwiftChessTools Guidance

This repository is the reusable Swift package for shared chess rules, notation,
UCI helpers, and SwiftUI chess components. Keep app-specific engine flows and
product behavior in separate apps such as `SwiftChessDemo`.

The package products are:

- `ChessCore`: board state, pieces, moves, legal move generation, FEN, and SAN.
- `ChessUI`: SwiftUI board and display components built on `ChessCore`.
- `ChessUCI`: typed UCI command-formatting and engine-output parsing helpers
  built on `ChessCore`.

## Scope Boundaries

`ChessUI` should stay display-focused and consumer-controlled. It may render
values supplied by an app, but it should not start Stockfish, run analysis,
choose moves, own game playback policy, or parse engine search streams.

For evaluation UI specifically, apps should normalize engine output into
White-positive `ChessEvaluation` values before passing them to ChessUI.

`ChessUCI` may format UCI text sent to an engine and parse UCI text emitted by
an engine, but it should not start or manage an engine process, decide engine
option policy, sequence readiness, schedule searches, or own analysis lifecycle
policy.

`Examples/ChessWorkbench` is the package-local macOS manual workbench. Keep it
thin and useful for exercising package APIs; do not move reusable behavior from
the package into the example app.

## Build And Test

Run focused checks from this repository root.

Swift package tests:

```sh
swift test
```

macOS Workbench build:

```sh
xcodebuild -project Examples/ChessWorkbench/ChessWorkbench.xcodeproj \
  -scheme ChessWorkbench \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/xcode-chess-workbench \
  build
```

macOS Workbench UI tests:

```sh
xcodebuild -project Examples/ChessWorkbench/ChessWorkbench.xcodeproj \
  -scheme ChessWorkbench \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/xcode-chess-workbench \
  -clonedSourcePackagesDirPath .build/xcode-chess-workbench/SourcePackages \
  test
```

iOS ChessUI harness tests:

```sh
xcodebuild -project Tests/ChessUIHarness/ChessUIHarness.xcodeproj \
  -scheme ChessUIHarness \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/xcode-harness \
  -clonedSourcePackagesDirPath .build/xcode-harness/SourcePackages \
  test
```

Combined repo suite:

```sh
Scripts/test-all.sh
```

The combined script also performs a Release build, runs the ChessCore recipe,
and compares the public API with the latest available Git tag before starting
the iOS and macOS UI suites. A checkout without tags skips only the API
comparison.

GitHub-hosted CI is intentionally manual-only and optional. It does not run on
pushes or pull requests, and neither a hosted run nor a successful hosted result
is an acceptance requirement. Focused local checks and `Scripts/test-all.sh`
remain the expected validation paths. Do not dispatch GitHub Actions during
ordinary validation unless the user explicitly asks. When requested, dispatch
the workflow for a branch or tag that already exists on GitHub with:

```sh
Scripts/run-github-ci.sh [ref]
```

The dispatcher never commits or pushes. The hosted workflow runs
`Scripts/github-ci.sh`, which contains the headless checks suitable for a
GitHub-hosted macOS runner.

If macOS UI tests report another app window as an interrupting element, move the
blocking window away and rerun before treating the failure as a product defect.

## Documentation And Release Notes

For major user-facing, public API, behavior, migration, or dependency changes,
update `CHANGELOG.md` under `Unreleased` before finishing.

Update `README.md` and `Examples/ChessWorkbench/README.md` when public ChessUI
or Workbench behavior changes.

Do not tag, release, or push unless the user explicitly asks.

## Generated Files

Do not commit generated build products, DerivedData, `.build`, `.swiftpm`, Xcode
user state, or refreshed snapshot references unless the user intentionally asked
for snapshot updates.
