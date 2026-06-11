# SwiftChessTools Guidance

This repository is the reusable Swift package in the chess workspace. Keep
shared rules, notation, and SwiftUI chess components here; keep app-specific
engine flows and product behavior in sibling apps such as `SwiftChessDemo`.

The package products are:

- `ChessCore`: board state, pieces, moves, legal move generation, FEN, and SAN.
- `ChessUI`: SwiftUI board and display components built on `ChessCore`.

## Scope Boundaries

`ChessUI` should stay display-focused and consumer-controlled. It may render
values supplied by an app, but it should not start Stockfish, run analysis,
choose moves, own game playback policy, or parse engine search streams.

For evaluation UI specifically, apps should normalize engine output into
White-positive `ChessEvaluation` values before passing them to ChessUI.

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
