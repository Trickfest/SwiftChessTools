# ChessTest

ChessTest is a small macOS SwiftUI test driver for the reusable chess UI and
rules code in `SwiftChessTools`.

It is not intended to be a product app. Keep it around as a quick place to
exercise `ChessCore` and `ChessUI` behavior without opening the larger demo app.

## What It Tests

- Rendering a `ChessUI.ChessBoardView` on macOS.
- Loading and editing a FEN position.
- Applying legal board moves through `ChessCore`.
- Updating the FEN field after board moves.
- Board sizing, hints, reset behavior, and the promotion picker UI.

## Local Dependency

The Xcode project uses the package root two levels up:

```text
../..
```

That package supplies:

- `ChessCore`
- `ChessUI`

## Run It

From the `SwiftChessTools` repository root, open the project in Xcode:

```sh
open Examples/ChessTest/ChessTest.xcodeproj
```

Select the `ChessTest` scheme and run it on My Mac.

Command-line build:

```sh
xcodebuild -project Examples/ChessTest/ChessTest.xcodeproj \
  -scheme ChessTest \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/xcode-chess-test \
  build
```

## Manual Smoke Test

1. Launch the app.
2. Confirm the board renders with the starting FEN.
3. Drag a legal piece move on the board.
4. Confirm the FEN field updates.
5. Try `Reset`, `Hint`, and `Show Promotion Picker`.

Use this example app when you need a small, disposable driver for future
`SwiftChessTools` UI or rules changes.
