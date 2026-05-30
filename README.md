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

## Testing

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
