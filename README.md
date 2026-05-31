# SwiftChessTools

SwiftChessTools is an independent Swift package for reusable chess tools that
can support multiple future apps.

Phase one focuses on preserving migrated behavior:

- `ChessCore`: core chess model, rules, and notation code.
- `ChessUI`: reusable SwiftUI chessboard UI built on `ChessCore`.

This package is not a drop-in replacement for ChessKit or ChessboardKit, and it
does not provide old-package compatibility shims.

## Package Products

```swift
.product(name: "ChessCore", package: "SwiftChessTools")
.product(name: "ChessUI", package: "SwiftChessTools")
```

## Manual Workbench

`Examples/ChessWorkbench` is a small macOS SwiftUI app for manually exercising
`ChessCore` and `ChessUI` without opening the larger iOS demo. It renders a
real `ChessBoardView`, lets you edit the current FEN, applies legal board
moves, and exposes quick controls for reset, hints, board sizing, and promotion
UI.

Open the app in Xcode:

```sh
open Examples/ChessWorkbench/ChessWorkbench.xcodeproj
```

Select the `ChessWorkbench` scheme and run it on My Mac.

Command-line build:

```sh
xcodebuild -project Examples/ChessWorkbench/ChessWorkbench.xcodeproj \
  -scheme ChessWorkbench \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/xcode-chess-workbench \
  build
```

Manual smoke test:

1. Launch the app.
2. Confirm the board renders from the starting FEN.
3. Drag a legal move on the board.
4. Confirm the FEN field updates.
5. Try `Reset`, `Hint`, and `Show Promotion Picker`.

## Testing

Run all automated tests from the repository root:

```sh
Scripts/test-all.sh
```

The script runs the SwiftPM test suite, the simulator-backed `ChessUIHarness`
XCUITest suite, and the macOS `ChessWorkbench` UI tests. To use a different
simulator or macOS destination, set `IOS_DESTINATION` or `MACOS_DESTINATION`.

Run the package test suite from the repository root:

```sh
swift test
```

Run the same suite with SwiftPM coverage enabled:

```sh
swift test --enable-code-coverage
```

ChessUI has macOS-rendered snapshot tests checked in under
`Tests/ChessUITests/SnapshotReferences`. To intentionally refresh those
references:

```sh
RECORD_CHESSUI_SNAPSHOTS=1 swift test --filter ChessUISnapshotTests
```

The simulator-backed ChessUI harness exercises the real SwiftUI board through
XCUITest:

```sh
xcodebuild -project Tests/ChessUIHarness/ChessUIHarness.xcodeproj \
  -scheme ChessUIHarness \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/xcode-harness \
  -clonedSourcePackagesDirPath .build/xcode-harness/SourcePackages \
  test
```

The macOS `ChessWorkbench` UI tests drive the package's example app directly:

```sh
xcodebuild -project Examples/ChessWorkbench/ChessWorkbench.xcodeproj \
  -scheme ChessWorkbench \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/xcode-chess-workbench \
  -clonedSourcePackagesDirPath .build/xcode-chess-workbench/SourcePackages \
  test
```

## Acknowledgements

This project draws significant inspiration from
[ChessKit](https://github.com/aperechnev/ChessKit) by Alexander Perechnev and
[ChessboardKit](https://github.com/rohanrhu/ChessboardKit) by Rohan R. H. U.
Early versions incorporate ideas and implementation approaches from those
projects. This repository is independent and is not affiliated with or endorsed
by the original maintainers.

See `NOTICE.md` for preserved MIT license notices.

## Roadmap

See `ROADMAP.md`.
