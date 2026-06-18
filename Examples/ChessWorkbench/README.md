# ChessWorkbench

ChessWorkbench is a small macOS SwiftUI workbench for the reusable chess UI and
rules code in `SwiftChessTools`. It opens with the Art Deco Monochrome piece set
and board theme selected so newly generated ChessUI artwork is visible
immediately.

It is not a product app. Keep it around as a quick place to exercise
`ChessCore` and `ChessUI` behavior from inside this package; its Xcode project
also hosts focused macOS UI tests for those workbench flows.

For the public ChessUI walkthrough, see
[../../Docs/ChessUITutorial.md](../../Docs/ChessUITutorial.md).

## What It Exercises

- Rendering a `ChessUI.ChessBoardView` on macOS.
- Loading and editing a FEN position.
- Applying legal board moves through `ChessCore`.
- Updating the FEN field after board moves.
- Exercising the default ChessUI board interaction mode, where the board
  reports move attempts and the workbench decides whether to apply them.
- Manually checking board accessibility labels, hints, and VoiceOver-style
  square activation for selecting pieces and reporting destination moves.
- Piece-set selection, board-theme selection, coordinate-label visibility,
  board sizing, hints, app-supplied arrow annotations, reset behavior, and the
  promotion picker UI.
- Fixed-size, scrolling `ChessMoveListView` display for legal moves made on the
  board, including vertical and horizontal layouts and scroll-bar visibility.
- `ChessGameStatusView` display for side-to-move, terminal statuses, and
  claimable draw callbacks.
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
5. With VoiceOver or the Accessibility Inspector, confirm a movable square can
   be selected, legal destinations are announced, and activating a destination
   reports the move.
6. Confirm the vertical move list records the legal move in SAN and stays at a
   fixed height as moves are added.
7. Change `Moves` from `Vertical` to `Horizontal` and confirm the move list
   appears above the board as a left-to-right strip.
8. Toggle `Scroll bars` and confirm the move list still scrolls and records
   legal moves.
9. Select each built-in piece set from the `Pieces` menu and confirm the board
   re-renders.
10. Select each built-in board theme from the `Board` menu and confirm the board
   re-renders.
11. Toggle `Coordinates` and confirm the board remains playable.
12. Confirm the `Status` section shows the side to move.
13. Paste a claimable draw FEN such as
   `4k3/8/8/8/8/8/Q7/4K3 w - - 100 1`, claim the draw, and confirm the
   status changes to a draw.
14. Change the evaluation sample and confirm the evaluation bar and status text
   update.
15. Change the evaluation placement and White-side controls and confirm the bar
   moves between the board edges.
16. Try `Show Best Arrow`, `Show Top Three`, and `Clear Arrows`.
17. Try `Reset`, `Hint`, and `Show Promotion Picker`.

Use this example app when you need a small, disposable workbench for future
`SwiftChessTools` UI or rules changes.
