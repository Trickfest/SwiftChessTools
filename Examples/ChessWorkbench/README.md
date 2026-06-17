# ChessWorkbench

ChessWorkbench is a small macOS SwiftUI workbench for the reusable chess UI and
rules code in `SwiftChessTools`. It opens with the Art Deco Monochrome piece set
and board theme selected so newly generated ChessUI artwork is visible
immediately.

It is not a product app. Keep it around as a quick place to exercise
`ChessCore` and `ChessUI` behavior from inside this package; its Xcode project
also hosts focused macOS UI tests for those workbench flows.

## What It Exercises

- Rendering a `ChessUI.ChessBoardView` on macOS.
- Loading and editing a FEN position.
- Applying legal board moves through `ChessCore`.
- Updating the FEN field after board moves.
- Exercising the default ChessUI board interaction mode, where the board
  reports move attempts and the workbench decides whether to apply them.
- Piece-set selection, board-theme selection, board sizing, hints, reset
  behavior, and the promotion picker UI.
- Fixed-size, scrolling `ChessMoveListView` display for legal moves made on the
  board, including vertical and horizontal layouts and scroll-bar visibility.
- `ChessEvaluationBar` samples, placement, White-side orientation, label
  visibility, and centipawn scale controls.

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

Command-line UI tests:

```sh
xcodebuild -project Examples/ChessWorkbench/ChessWorkbench.xcodeproj \
  -scheme ChessWorkbench \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/xcode-chess-workbench \
  -clonedSourcePackagesDirPath .build/xcode-chess-workbench/SourcePackages \
  test
```

To run every automated `SwiftChessTools` suite, including these Workbench UI
tests, use the repo-level script from the package root:

```sh
Scripts/test-all.sh
```

## Manual Smoke Test

1. Launch the app.
2. Confirm the board renders with the starting FEN.
3. Drag a legal piece move on the board.
4. Confirm the FEN field updates.
5. Confirm the vertical move list records the legal move in SAN and stays at a
   fixed height as moves are added.
6. Change `Moves` from `Vertical` to `Horizontal` and confirm the move list
   appears above the board as a left-to-right strip.
7. Toggle `Scroll bars` and confirm the move list still scrolls and records
   legal moves.
8. Select each built-in piece set from the `Pieces` menu and confirm the board
   re-renders.
9. Select each built-in board theme from the `Board` menu and confirm the board
   re-renders.
10. Change the evaluation sample and confirm the evaluation bar and status text
   update.
11. Change the evaluation placement and White-side controls and confirm the bar
   moves between the board edges.
12. Try `Reset`, `Hint`, and `Show Promotion Picker`.

Use this example app when you need a small, disposable workbench for future
`SwiftChessTools` UI or rules changes.
