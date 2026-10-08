# ChessWorkbench

The Display panel includes a **Piece size** slider (50–100%) and **Default**
reset for the selected piece set. Each set retains its own value for the
current window session. Try compact and large boards, move or drag a piece,
and open promotion to compare sizing across all artwork paths.

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

The Workbench uses `GameTimeline`, `ChessMoveNavigationView`,
selected-move list scrolling, and `ChessBoardModel.setGame(_:)` for complete
historical game display. See the
[navigation tutorial](../../Docs/ChessUITutorial.md#move-navigation)
for the caller-controlled APIs and opt-in keyboard policy.

- Rendering a `ChessUI.ChessBoardView` on macOS.
- Loading and editing a FEN position.
- Applying legal board moves through `ChessCore`.
- Updating the FEN field after board moves.
- Exercising the default ChessUI board interaction mode, where the board
  reports move attempts and the workbench decides whether to apply them.
- Manually checking board accessibility labels, hints, and VoiceOver-style
  square activation for selecting or reselecting pieces and reporting
  destination moves.
- Piece-set selection, board-theme selection, inside/outside/hidden coordinate
  labels,
  board sizing, hints, app-supplied arrow annotations, reset behavior, and the
  promotion picker UI.
- Fixed-size, scrolling `ChessMoveListView` display for legal moves made on the
  board, including vertical and horizontal layouts and scroll-bar visibility.
  Vertical move-number columns expand for long games without wrapping periods.
- Start/previous/next/end navigation and direct move-list selection, with the
  board, FEN, status, selected move, and last-move highlight synchronized.
  The full padded move label is clickable, including unselected moves.
- `ChessGameStatusView` display for side-to-move, terminal statuses, and
  claimable draw callbacks.
- `ChessEvaluationBar` samples, placement, White-side orientation, label
  visibility, and centipawn scale controls.

## Timeline Editing and Manual Review

The four controls below the board browse the recorded line. The position
counter uses half-moves: zero is the loaded root. Left/Right step and
Command-Left/Right jump to the start/end. Shortcuts are disabled while the FEN
editor or promotion picker is active. Click a navigation button or the board
to leave FEN editing before using shortcuts.

- A legal board move at the end appends to the line.
- Playing the already recorded next move advances without deleting the future.
- Playing a different legal move immediately replaces the remaining continuation.
- Finished displayed positions reject new board moves. You can still browse
  the line or rewind before an ending and choose another continuation.
- Draw claims are remembered by Workbench at their selected position, including
  after navigating away and back. Replacing the claimed continuation or loading
  a new root discards its claim; the timeline itself does not store outcomes.
- Editing a valid FEN starts a new line, including pasting the currently displayed
  FEN. Invalid notation or an invalid root leaves the existing board/history
  unchanged and shows an error. Navigation replaces that draft with displayed FEN.
- Reset restores the original sample root and clears the entire line and claims,
  even when the board was already showing that root. Board preferences remain.
- Position changes clear stale selection, promotion, hints, and arrows. Evaluation
  remains the manually selected sample, not analysis of the displayed position.

Suggested hands-on review:

1. Paste the standard starting FEN below, then play `e2-e4`, `e7-e5`, `g1-f3`.
2. Use all four buttons and click moves in the list. Confirm board, FEN, status,
   highlights, counter, and disabled boundary buttons agree.
3. Return to Start and play `e2-e4` again: all three recorded moves should remain.
4. Return to Start and play `d2-d4`: the line should now contain only `d4`.
5. Try both move-list layouts, outside coordinates, and piece sizing. Navigation
   and Reset should preserve these preferences. Check the controls at your
   preferred window and board sizes.
6. Enter invalid FEN and confirm the board/history survive; load another valid
   FEN and confirm it becomes position zero with an empty list.
7. Try arrow shortcuts on the board, then use arrow keys inside the FEN editor
   and confirm they edit/move the text cursor without navigating history.

```text
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

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
5. With VoiceOver or the Accessibility Inspector, touch a movable square
   directly and confirm its piece and coordinate are announced. Activate it,
   confirm legal destinations are announced, activate a different friendly
   piece to replace the source without reporting a move, and activate a
   destination to report the move.
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
11. Change `Coords` from `Inside` to `Outside`, confirm the board shrinks within
    the same card while labels move to the left and bottom, then choose `Hidden`
    and confirm the board again fills its original frame. Confirm the board
    remains playable in every mode.
12. Confirm the `Status` section shows the side to move.
13. Paste a claimable draw FEN such as
   `4k3/8/8/8/8/8/Q7/4K3 w - - 100 1`, claim the draw, and confirm the
   status changes to a draw.
14. Change the evaluation sample and confirm the evaluation bar and status text
   update.
15. Change the evaluation placement and White-side controls and confirm the bar
   moves between the board edges.
16. Try `Show Best Arrow`, `Show Top Three`, and `Clear Arrows`.
17. Try `Reset Position`, `Show d3 Marker`, and `Show Promotion`.

Use this example app when you need a small, disposable workbench for future
`SwiftChessTools` UI or rules changes.
