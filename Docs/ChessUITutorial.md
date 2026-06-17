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

## 7. Highlights And Hints

Legal-move highlights are enabled by default:

```swift
boardModel.showsLegalMoveHighlights = true
```

The board updates legal highlights during normal selection and drag gestures.
You can also control them directly:

```swift
boardModel.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))
boardModel.clearLegalMoveHighlights()
```

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

## 8. Board Interaction Modes

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

## 9. Piece Sets And Board Themes

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

## 10. Evaluation Bars

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

## 11. Move Lists

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

## 12. Game Status

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

## 13. Accessibility

ChessUI sets stable labels and identifiers for its reusable surfaces. These are
useful for VoiceOver, UI tests, and app-level integration checks.

Board squares expose coordinate-based identifiers:

```text
ChessUI.square.e4
```

Square labels describe the visible contents, such as:

```text
White pawn e4
Empty e5
```

Other useful identifiers include:

- `ChessUI.legalMove.e4`
- `ChessUI.lastMove.e2`
- `ChessUI.hint.d3`
- `ChessUI.promotion.queen`
- `ChessUI.evaluationBar`
- `ChessUI.moveList`
- `ChessUI.moveList.move.2`
- `ChessUI.gameStatus`
- `ChessUI.gameStatus.claim.fiftyMoveRule`

When wrapping ChessUI views in app-specific containers, avoid hiding the child
accessibility tree unless you intentionally replace it with equivalent labels
and actions.

## 14. Workbench

`Examples/ChessWorkbench` is the package-local macOS app for manually checking
ChessCore and ChessUI behavior:

```sh
open Examples/ChessWorkbench/ChessWorkbench.xcodeproj
```

Run the `ChessWorkbench` scheme on My Mac. The app exercises board rendering,
FEN editing, move application, promotion UI, hints, piece sets, board themes,
move lists, evaluation bars, and game status display.

The workbench is intentionally thin. Reusable behavior belongs in
`Sources/ChessUI` or `Sources/ChessCore`, not in the example app.

## 15. Scope Boundaries

ChessUI provides:

- A reusable SwiftUI board.
- Board interaction callbacks.
- Piece-set and board-theme selection.
- Legal-move, hint, and last-move highlights.
- Promotion picker UI.
- Evaluation bar rendering for caller-supplied values.
- Move-list rendering for caller-supplied records.
- Game-status rendering for caller-supplied status values.

ChessUI does not provide:

- A chess engine.
- Stockfish integration.
- Engine search parsing.
- Automatic move selection.
- PGN parsing or full PGN browsing UI.
- Clocks, resignation, timeout, accounts, sync, online play, or persistence.

Keep app policy in the app. Pass display-ready values into ChessUI, handle
callbacks at the app boundary, and use ChessCore for rules and notation.
