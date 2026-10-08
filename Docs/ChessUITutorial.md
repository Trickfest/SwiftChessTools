# ChessUI Tutorial

This tutorial introduces `ChessUI`, the SwiftUI module in SwiftChessTools.
`ChessUI` renders chess views and reports user intent. It builds on
`ChessCore`, but it does not take ownership of app policy, engine analysis,
clocks, online play, PGN browsing, or game records.

The working model:

> `ChessBoardModel` stores display state for one board, `ChessBoardView`
> renders it, move callbacks report `ChessBoardMoveAttempt` values, and the
> app decides how to update `Game`, FEN, move lists, status, and engine state.

## 1. Install And Import

Add SwiftChessTools as a package dependency, then depend on the `ChessUI`
product from your target. Most apps that use `ChessUI` also depend on
`ChessCore`.

```swift
import SwiftUI
import ChessCore
import ChessUI
```

For local development in this workspace, use a path dependency:

```swift
.package(path: "../SwiftChessTools")
```

Then add the products your target needs:

```swift
.product(name: "ChessCore", package: "SwiftChessTools")
.product(name: "ChessUI", package: "SwiftChessTools")
```

## 2. The Fastest Useful Board

Create a `ChessBoardModel`, render it with `ChessBoardView`, and apply legal
moves in the move callback:

```swift
struct BoardScreen: View {
    @State private var boardModel = ChessBoardModel(
        fen: initialFEN,
        interactionMode: .legalMovesOnly
    )

    var body: some View {
        ChessBoardView(model: boardModel)
            .onMove(applyMove)
            .frame(width: 320, height: 320)
    }

    private func applyMove(_ attempt: ChessBoardMoveAttempt) {
        guard attempt.isLegal else {
            return
        }

        boardModel.game.apply(move: attempt.move)

        let fen = FENSerializer().fen(from: boardModel.game.position)
        boardModel.setFEN(fen, animatedMove: attempt.move)
    }
}
```

`ChessBoardView` does not mutate the game for you. It reports the attempted
move, and your app decides whether and how to apply it.

## 3. Model Ownership

Own `ChessBoardModel` at the same level that owns the board's current game
state. For a simple SwiftUI screen, `@State` is usually the right owner:

```swift
@State private var boardModel = ChessBoardModel(fen: initialFEN)
```

If a parent view owns the model, pass the same instance down to child views:

```swift
struct BoardPane: View {
    var boardModel: ChessBoardModel

    var body: some View {
        ChessBoardView(model: boardModel)
    }
}
```

Avoid keeping separate unsynchronized sources of truth for the same game. If
your app has an external `Game`, either make that game the authority and push
FEN into the board model, or use `boardModel.game` as the authority and derive
other UI from it.

To replace the board with FEN, use `setFEN`:

```swift
let didUpdate = boardModel.setFEN(importedFEN)

if !didUpdate {
    print(boardModel.fenError ?? "Unknown FEN error")
}
```

Invalid FEN leaves the existing board unchanged and records the parser error in
`fenError`. Use `setFEN(_:animatedMove:)` after a known move when you want the
last-move highlight and piece animation to match the update.

When the incoming position equals `boardModel.game.position`, `setFEN` retains
that same `Game` instance. This is what preserves move history, repetition
counts, and draw claims in the documented apply-move-then-render flow. A
different imported position creates a new `Game`. Every successful update
clears position-specific selection, legal-move, drag, and pending-promotion
state; caller-owned hints and arrows remain until the app clears them.

## 4. Move Attempts

`ChessBoardView.onMove(_:)` receives a `ChessBoardMoveAttempt`:

```swift
.onMove { attempt in
    print(attempt.coordinateMove)
    print(attempt.sourceSquare)
    print(attempt.targetSquare)
    print(attempt.isLegal)
}
```

The modifier keeps its callback with the view rather than making the model own
the closure. Prefer it for app callbacks. `ChessBoardModel.onMove` remains as a
direct-configuration fallback; if you use that property, avoid strongly
capturing an owner that also retains the model.

The attempt contains:

- `move`: the parsed `Move`.
- `isLegal`: whether the move is legal in the model's current `Game`.
- `sourceSquare` and `targetSquare`: coordinate strings such as `e2` and `e4`.
- `coordinateMove`: normalized coordinate notation such as `e2e4` or
  `e7e8q`.
- `promotion`: the selected promotion piece, when applicable.

For normal games, set `interactionMode` to `.legalMovesOnly` and apply each
reported move:

```swift
boardModel.interactionMode = .legalMovesOnly
```

For surfaces that need to show rejected attempts, use
`.reportsIllegalAttempts` and handle `attempt.isLegal == false`.

## 5. Promotion Handling

For board gestures, `ChessBoardView` presents its promotion picker when a pawn
move reaches the last rank and at least one promotion choice is legal. The
callback fires after the user selects a piece:

```swift
.onMove { attempt in
    if attempt.promotion == .queen {
        print("Promoted with \(attempt.coordinateMove)")
    }
}
```

The resulting move includes the promotion kind:

```text
e7e8q
```

The picker uses the promoting pawn's color regardless of board perspective and
adapts its spacing for small board frames.

Most apps do not need to present the picker directly. If you are building a
custom setup or tutorial flow, `ChessBoardModel` also exposes
`presentPromotionPicker(...)`, `dismissPromotionPicker()`, and
`requiresPromotionChoice(piece:move:)`.

## 6. Perspective

Use `perspective` to choose which side appears at the bottom:

```swift
boardModel.perspective = .white
boardModel.perspective = .black
```

The board keeps coordinates logical after flipping. A tap or drag from `e2` to
`e4` still reports `e2e4` when Black is at the bottom.

Use `shouldFlipBoard` only when you are building adjacent UI that needs to align
with the board's orientation.

Rank and file coordinate labels are shown inside the board by default. This
keeps existing clients and their board appearance unchanged. To place ranks to
the left and files below the board instead, set the placement on an existing
model:

```swift
boardModel.coordinateLabelPlacement = .outside
```

You can also choose outside labels when creating the model:

```swift
let boardModel = ChessBoardModel(
    fen: initialFEN,
    coordinateLabelPlacement: .outside
)
```

Outside-label mode keeps the complete board and its dark left-and-bottom
coordinate gutters inside the same `ChessBoardView` frame by shrinking the
playable 8×8 surface. The top and right edges remain flush, and the rank and
file order follows White or Black perspective automatically.

Hide labels for cleaner diagrams, training modes, or app surfaces that provide
their own coordinates:

```swift
boardModel.showsCoordinateLabels = false
```

Hiding labels reserves no outside gutter. Visibility and placement are
separate settings, so showing labels again restores the previously selected
placement.

## 7. Highlights And Hints

Legal-move highlights are enabled by default:

```swift
boardModel.showsLegalMoveHighlights = true
```

The board updates legal highlights during normal selection and drag gestures.
If a source is already selected, tapping another movable piece of the same
color replaces the selection instead of reporting a move attempt. Tapping the
selected piece again clears the selection.
You can also control them directly:

```swift
boardModel.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))
boardModel.clearLegalMoveHighlights()
```

Turning `showsLegalMoveHighlights` off also clears any markers that were already
calculated. Off-board `BoardSquare` values are ignored by highlight and hint
entry points.

Last-move highlighting is enabled by default and is normally driven by
`setFEN(_:animatedMove:)`:

```swift
boardModel.setFEN(fen, animatedMove: move)
boardModel.clearLastMoveHighlight()
```

Use hints for app-supplied visual markers:

```swift
boardModel.hint("e4")
boardModel.hint(["e4", "d5"])
boardModel.hint("e4", for: 1.5)
boardModel.clearHint()
```

Hints are display markers only. They do not affect legal move generation.
Starting a new timed hint cancels the prior cleanup timer so an older request
cannot clear a newer hint early. Non-finite or nonpositive durations clear
immediately; timed hints are capped at one day. Move-animation durations are
normalized to `0...60` seconds.

## 8. Board Arrows

Use board arrows for app-supplied visual annotations, such as engine
suggestions, training hints, or study marks:

```swift
boardModel.arrows = [
    ChessBoardArrow(from: "e2", to: "e4", style: .primarySuggestion),
    ChessBoardArrow(from: "d2", to: "d4", style: .secondarySuggestion),
    ChessBoardArrow(from: "g1", to: "f3", style: .tertiarySuggestion),
].compactMap { $0 }
```

Clear arrows when the position changes or when the annotation no longer
applies:

```swift
boardModel.clearArrows()
```

The built-in arrow styles are display conventions only:

- `.primarySuggestion`: strongest suggested move.
- `.secondarySuggestion`: second suggested move.
- `.tertiarySuggestion`: third suggested move.
- `.annotation`: general-purpose non-ranked arrow.

If your app shows more than three ranked lines, choose custom styles or use
`.annotation` for non-ranked extras:

```swift
let studyArrow = ChessBoardArrow(
    from: BoardSquare(row: 1, column: 4),
    to: BoardSquare(row: 3, column: 4),
    style: ChessBoardArrowStyle(red: 0.45, green: 0.20, blue: 0.78),
    label: "Study annotation"
)
```

Arrows follow board perspective automatically. They do not affect legal move
generation, selection, drag behavior, move application, or game status.
ChessUI does not analyze a position or decide whether a `.primarySuggestion`
arrow is actually best; the app supplies already-ranked display data.

## 9. Board Interaction Modes

`ChessBoardInteractionMode` describes what the board reports:

- `.readOnly`: no tap or drag move interaction.
- `.legalMovesOnly`: reports legal moves for the side to move.
- `.reportsIllegalAttempts`: reports legal and illegal attempts for the side to
  move.
- `.freeSetup`: reports legal and illegal attempts for either side's pieces.

Use `.readOnly` for analysis diagrams, PGN replay positions, and passive board
previews:

```swift
ChessBoardModel(fen: fen, interactionMode: .readOnly)
```

Use `.legalMovesOnly` for normal playable boards:

```swift
boardModel.interactionMode = .legalMovesOnly
```

Use `.freeSetup` for editors or setup surfaces. ChessUI still reports whether
the coordinate move is legal in the current `Game`, but the app decides what a
drag means.

## 10. Piece Sets And Board Themes

Piece sizing can be customized per board and per bundled set:

```swift
model.pieceRenderingScaleOverrides[.sashiteMerida] = 0.76
model.pieceRenderingScaleOverrides[.origamiMonochrome] = 0.90
let currentScale = model.effectiveRenderingScale(for: model.pieceSet)
model.pieceRenderingScaleOverrides[.sashiteMerida] = nil
```

An absent override uses `ChessPieceSet.renderingScale`: `0.80` for Sashite
Merida and `0.85` for other sets. Finite values clamp to `0.50...1.00`;
nonfinite values remove the entry. The factor scales the fitted image,
including its transparent padding. Stationary, dragged, animated, and promotion
pieces use the same factor. Board geometry, square targets, and accessibility
frames are preserved. Changing `pieceSet` recalls that set's override.

The additive `ChessBoardModel` initializer overload accepts
`pieceRenderingScaleOverrides` together with optional coordinate placement.
Existing initializers keep their defaults. An app can bind a slider to
`effectiveRenderingScale(for:)` and update the selected set's dictionary entry;
the app owns any saving across games or launches.

`ChessUI` ships with selectable piece sets and board themes. Use the runtime
registries to build pickers:

```swift
struct BoardSettingsView: View {
    @State private var boardModel = ChessBoardModel(fen: initialFEN)

    var body: some View {
        @Bindable var editableModel = boardModel

        VStack {
            Picker("Pieces", selection: $editableModel.pieceSet) {
                ForEach(ChessPieceSet.availableSets) { pieceSet in
                    Text(pieceSet.displayName).tag(pieceSet)
                }
            }

            Picker("Board", selection: $editableModel.boardTheme) {
                ForEach(ChessBoardTheme.availableThemes) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }

            ChessBoardView(model: boardModel)
        }
    }
}
```

The registries are the stable app-facing way to expose bundled options:

```swift
let pieceSets = ChessPieceSet.availableSets
let boardThemes = ChessBoardTheme.availableThemes
```

Apps can choose fixed defaults, expose pickers, or store the selected raw values
in their own preferences.

## 11. Evaluation Bars

`ChessEvaluationBar` renders caller-supplied evaluation values. It does not
start an engine, parse UCI output, choose moves, or run analysis.

```swift
ChessEvaluationBar(
    evaluation: .centipawns(85),
    orientation: .vertical,
    whiteSide: .bottom,
    maximumCentipawns: 800
)
.frame(width: 28, height: 320)
```

Centipawns are White-positive:

```swift
ChessEvaluation.centipawns(120)   // White is better
ChessEvaluation.centipawns(-90)   // Black is better
ChessEvaluation.centipawns(0)     // Equal
```

Forced mate values identify the side delivering mate:

```swift
ChessEvaluationBar(evaluation: .mate(moves: 3, side: .white))
ChessEvaluationBar(evaluation: .mate(moves: 2, side: .black))
```

Use `.unavailable` when the app has no current evaluation:

```swift
ChessEvaluationBar(evaluation: .unavailable)
```

If you need text without rendering a view, use
`ChessEvaluationBarDisplayState`:

```swift
let state = ChessEvaluationBarDisplayState(evaluation: .centipawns(85))
print(state.label)
print(state.accessibilityValue)
```

Apps that consume engines such as Stockfish should normalize engine output into
these values before passing them to ChessUI.

## 12. Move Lists

`ChessMoveListView` renders display-ready move records. It does not parse PGN,
own a game history, or render a full PGN score sheet.

Build records from moves with `ChessMoveRecordBuilder`:

```swift
let records = try ChessMoveRecordBuilder().records(
    initialPosition: Position.standard,
    moves: game.moveHistory
)
```

Render a vertical move list:

```swift
ChessMoveListView(
    records: records,
    selectedPly: selectedPly
) { record in
    selectedPly = record.ply
}
.frame(height: 160)
```

The default vertical layout groups White and Black moves by full move number.
Give the list a fixed height so it can scroll inside a predictable viewport.

Use horizontal layout for a compact move strip:

```swift
ChessMoveListView(
    records: records,
    selectedPly: selectedPly,
    title: nil,
    layout: .horizontal,
    scrollIndicatorVisibility: .hidden
) { record in
    selectedPly = record.ply
}
.frame(height: 48)
```

The selected ply is visual state only. The app decides what selection means:
jumping to a position, showing annotation, updating a side panel, or doing
nothing.

### Move Navigation

`ChessMoveNavigationView` provides caller-controlled navigation. Supply a
zero-based position index (`selectedPly`) and the number of
recorded half-moves (`moveCount`). Position zero is the initial position, even
for a custom FEN beginning with Black or a later full move number.

```swift
struct HistoryControls: View {
    let timeline: GameTimeline
    @Binding var selectedPly: Int
    var isActiveBoard = false
    var isEditingText = false

    var body: some View {
        ChessMoveNavigationView(
            selectedPly: selectedPly,
            moveCount: timeline.moveCount,
            keyboardShortcutsEnabled: isActiveBoard && !isEditingText
        ) { requestedPly in
            selectedPly = requestedPly
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        .frame(maxWidth: 340)
    }
}
```

The caller may accept, defer, or ignore the callback. Ignoring it leaves the
control's selection unchanged. Growing a recorded line does not automatically
follow its end. The app must synchronize its displayed game, board, and move
list when accepting a selection; the widget does none of that on its own.
It also works without `GameTimeline` if an app has another linear history.

Empty lines disable all four buttons. At the start or end, unavailable actions
are disabled. Negative counts, negative selections, and selections beyond the
recorded end disable every action without clamping app state. Use
`ChessMoveNavigationState.destination(for:)` with a `ChessMoveNavigationAction`
to apply the same rules in custom app controls or commands.

Buttons inherit the surrounding `buttonStyle`, tint, and enabled state. Each
label has a minimum width of 44 points and height of 48 points; the four buttons
are separated by 10 points. Allow sufficient width (at least 206 points before
any custom style's padding) and avoid clipping the outer view. Icons scale with
Dynamic Type. Native button accessibility includes action labels and hints;
the group describes the selected ply and recorded count. Button identifiers
are `ChessUI.moveNavigation.start`, `.previous`, `.next`, and `.end`.

Shortcuts are **off by default**. When explicitly enabled, Left/Right request
the previous/next ply and Command-Left/Command-Right request the start/end.
SwiftUI keyboard shortcuts apply across the active window or scene, not just
when the bar has focus. Enable them for only one active board and turn them off
while editing FEN, PGN, or other text. Apps with existing commands should keep
this option off and reuse the state helper in those commands. See Apple's
[keyboardShortcut documentation](https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:)-3vjx6).

### Synchronizing a Historical Board and Move List

For browsing, opt into selected-move scrolling in either layout:

```swift
ChessMoveListView(
    records: timeline.moveRecords,
    selectedPly: selectedPly,
    layout: .horizontal,
    scrollBehavior: .selectedMove
) { record in
    select(record.ply)
}
```

The original initializer still follows the newest move when content overflows.
With `.selectedMove`, the list reveals the selected record on appearance,
selection changes, content replacement/growth, or viewport changes. It does not
change selection or invoke the callback itself. At ply zero it reveals the
beginning with no selected row. Nil or unavailable selections request no scroll.
Automatic scrolling respects Reduce Motion. A newly selected ply cancels any
pending earlier scroll request.

Route list taps and navigation-bar requests through the same app-owned method:

```swift
private func select(_ ply: Int) {
    do {
        let displayedGame = try timeline.game(atPly: ply)
        boardModel.setGame(displayedGame)
        selectedPly = ply
    } catch {
        // Keep the existing display and selection; report the error in app UI.
        navigationError = error.localizedDescription
    }
}
```

The example assumes app-owned `timeline`, `boardModel`, `selectedPly`, and
`navigationError` properties. Call it for the initial display as well, and
again after replacing a line even if the selected ply has not changed.

`setGame(_:)` copies the entire supplied `Game`: position, move history,
repetition counts, and an existing claimed draw. Subsequent mutations of either
copy are independent. It uses the final history move for the displayed-move
highlight; an empty history clears the highlight. Selection, drag feedback,
in-flight gestures, pending promotion, FEN errors, and animation are cleared.
Position jumps are immediate, including backward jumps. Perspective, theme,
piece set/scales, coordinate placement, highlight preferences, interaction mode,
waiting state, and callbacks stay unchanged. Hints and arrows remain
caller-owned; clear or recompute them when they refer to a different position.

Existing `setFEN(_:animatedMove:)` behavior remains available for animated live
play. Loading a different FEN cannot reconstruct repetition history, so use
`setGame(_:)` when supplying a reconstructed historical game. `GameTimeline`
cannot infer an earlier explicit draw claim, resignation, or timeout; carrying
such outcomes remains app policy. Neither API starts/stops an engine or edits
the authoritative live game.

### Browsing While a Live Game Continues

[SwiftChessDemo](https://github.com/Trickfest/SwiftChessDemo)
uses these APIs in both human-vs-engine and engine-vs-engine gameplay. It keeps
the live `Game` separate from the board's displayed copy. Engine requests,
reply validation, legal moves, claims, and results always use the live game.

When a live move arrives, the app records whether the user was at the old end,
appends the move to its timeline, and advances the selected ply only when the
user was following live play. Otherwise the historical board stays unchanged.
Selecting the new end resumes live following. This follow policy belongs to
the app, not the navigation bar or move list.

Historical boards are read-only; the app hides live suggestion arrows and
supplies a recorded evaluation only when it matches the selected old position.
The engine/depth label distinguishes that recorded estimate from live output,
and unscored positions remain unavailable. The app owns this score cache; the
timeline and evaluation-bar widget do not start analysis. It labels
live engine activity separately from historical status and offers Return to
Live. Changing display position neither starts a historical search nor changes
the live engine-vs-engine pause state. To preserve an actual draw claim at the
live end, the app displays its authoritative Game rather than inferring the
claim from the timeline's move sequence. Resignation, timeout, and other
app-specific outcomes still require separate app-owned state and presentation.

See Demo's `GameViewModel.swift` for the state boundary and `GameView.swift`
for the consumer-owned controls. ChessWorkbench demonstrates the alternative
policy: an editable linear exploration session whose future is preserved when
replaying the same next move and replaced when playing a different move.

## 13. Game Status

`ChessGameStatusView` renders caller-supplied `GameStatus` values:

```swift
ChessGameStatusView(
    status: game.status,
    turn: game.position.state.turn
)
```

For claimable draws, provide a callback:

```swift
ChessGameStatusView(
    status: game.status,
    turn: game.position.state.turn
) { claim in
    try? game.claimDraw(claim)
}
```

The callback receives a `GameDrawClaim`. The app still owns the `Game` and
decides whether to apply the claim, update surrounding state, write a result,
or ask for confirmation.

Use `ChessGameStatusDisplayState` when you need text outside SwiftUI:

```swift
let display = ChessGameStatusDisplayState(
    status: game.status,
    turn: game.position.state.turn
)

print(display.text)
```

`ChessGameStatusView` does not decide resignations, timeouts, adjudications, or
external result markers. Those are app policy.

## 14. Accessibility

ChessUI sets stable labels and identifiers for its reusable surfaces. These are
useful for VoiceOver, UI tests, and app-level integration checks.

`ChessBoardView` supports the same source-and-destination move flow through
accessibility actions that it supports through taps:

1. Activate a movable piece square to select it.
2. Listen for the selected piece and legal destination announcement.
3. If needed, activate another movable piece of the same color to replace the
   source selection without reporting an attempt.
4. Activate a destination square to report the move attempt through
   `onMove(_:)`.
5. If the move promotes a pawn, choose the promotion piece from the picker.

ChessUI still does not apply the move for you. Accessibility activation reports
the same `ChessBoardMoveAttempt` value as tap and drag gestures, so the app
keeps ownership of validation policy, state mutation, engine replies, and
surrounding UI.

Board squares expose coordinate-based identifiers:

```text
ChessUI.square.e4
```

Square labels describe the visible contents and interaction state, such as:

```text
White pawn, e2
White pawn, e2, selected
Empty, e4, legal destination
Black pawn, d5, legal capture
Black pawn, e7, not side to move
```

Square hints describe the expected action, such as selecting a piece, moving to
a legal destination, capturing, replacing or clearing the current selection,
or reporting an illegal attempt when configured. Read-only boards remain
accessible for inspection, but their squares do not expose move actions.

The waiting overlay disables accessibility move actions, and the promotion
picker behaves as a modal accessibility surface while it is presented.
Decorative rank and file labels are hidden from VoiceOver because each square
already includes its coordinate.

Other useful identifiers include:

- `ChessUI.legalMove.e4`
- `ChessUI.lastMove.e2`
- `ChessUI.hint.d3`
- `ChessUI.arrow.e2.e4`
- `ChessUI.promotion.queen`
- `ChessUI.evaluationBar`
- `ChessUI.moveList`
- `ChessUI.moveList.move.2`
- `ChessUI.gameStatus`
- `ChessUI.gameStatus.claim.fiftyMoveRule`

When wrapping ChessUI views in app-specific containers, avoid hiding the child
accessibility tree unless you intentionally replace it with equivalent labels
and actions.

## 15. Workbench

`Examples/ChessWorkbench` is the package-local macOS app for manually checking
ChessCore and ChessUI behavior:

```sh
open Examples/ChessWorkbench/ChessWorkbench.xcodeproj
```

Run the `ChessWorkbench` scheme on My Mac. The app exercises board rendering,
FEN editing, move application, promotion UI, hints, coordinate-label placement
and visibility,
app-supplied arrows, piece sets, board themes, move lists, evaluation bars, and
game status display.

The workbench is intentionally thin. Reusable behavior belongs in
`Sources/ChessUI` or `Sources/ChessCore`, not in the example app.

## 16. Scope Boundaries

ChessUI provides:

- A reusable SwiftUI board.
- Board interaction callbacks.
- Piece-set and board-theme selection.
- Coordinate-label placement and visibility.
- Legal-move, hint, last-move, and app-supplied arrow annotations.
- Board accessibility labels, hints, and square activation actions.
- Promotion picker UI.
- Evaluation bar rendering for caller-supplied values.
- Move-list rendering for caller-supplied records.
- Game-status rendering for caller-supplied status values.

ChessUI does not provide:

- A chess engine.
- Stockfish integration.
- Engine search parsing.
- Automatic move selection.
- Principal-variation ranking or best-move generation.
- PGN parsing or full PGN browsing UI.
- Clocks, resignation, timeout, accounts, sync, online play, or persistence.

Keep app policy in the app. Pass display-ready values into ChessUI, handle
callbacks at the app boundary, and use ChessCore for rules and notation.
