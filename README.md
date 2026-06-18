# SwiftChessTools

SwiftChessTools is an independent Swift package for reusable chess rules,
notation, and SwiftUI board UI that can support multiple future apps.

- `ChessCore`: core chess model, rules, and notation code.
- `ChessUI`: reusable SwiftUI chessboard UI built on `ChessCore`.

## Requirements

SwiftChessTools uses Swift tools 6.1 and supports Swift 5 and Swift 6 language
modes. The package currently declares these platform minimums:

- iOS 17+
- macOS 14+

## Installation

After the initial public release is tagged, add SwiftChessTools to your package
dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/Trickfest/SwiftChessTools.git",
        from: "1.0.0"
    ),
]
```

Then depend on the product or products your target needs:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "ChessCore", package: "SwiftChessTools"),
            .product(name: "ChessUI", package: "SwiftChessTools"),
        ]
    ),
]
```

For local development in a sibling checkout, use a path dependency instead:

```swift
.package(path: "../SwiftChessTools")
```

## Package Products

```swift
.product(name: "ChessCore", package: "SwiftChessTools")
.product(name: "ChessUI", package: "SwiftChessTools")
```

## ChessCore Quick Start

Use `ChessCore` when you need rules, positions, legal moves, and notation
without any SwiftUI dependency:

```swift
import ChessCore

let fenSerializer = FENSerializer()
let game = Game()

try game.applyLegal(move: "e2e4")

let updatedFEN = fenSerializer.fen(from: game.position)
let legalReplies = game.legalMoves.map(\.description)
```

FEN, SAN, and coordinate-move parsing APIs are throwing entry points:

```swift
do {
    let position = try FENSerializer().position(from: Position.standardStartingFEN)
    let coordinateGame = Game(position: position)
    let sanGame = Game(position: position)
    let coordinateMove = try Move(string: "g1f3")
    let sanMove = try SANSerializer().move(for: "e4", in: sanGame)
    try coordinateGame.applyLegal(move: coordinateMove)
    try sanGame.applyLegal(move: sanMove)
} catch let error as FENParsingError {
    // Handle malformed FEN.
} catch let error as SANParsingError {
    // Handle SAN that does not identify exactly one legal move.
} catch let error as MoveParsingError {
    // Handle malformed coordinate notation.
} catch let error as GameApplyError {
    // Handle a coordinate move that is well-formed but illegal.
} catch {
    // Handle any other error.
}
```

When accepting external FEN, use strict semantic validation or inspect a
non-throwing validation result:

```swift
let position = try FENSerializer().validatedPosition(from: Position.standardStartingFEN)
let validation = FENSerializer().validationResult(for: Position.standardStartingFEN)
```

### PGN Import And Export

`PGNSerializer` parses Portable Game Notation in `ChessCore`. It lexes PGN
syntax first, then semantically replays SAN through `Game` and `SANSerializer`
so parsed move records contain concrete, validated `Move` values.

```swift
let pgnText = """
    [Event "Example"]
    [Site "?"]
    [Date "????.??.??"]
    [Round "?"]
    [White "White"]
    [Black "Black"]
    [Result "1-0"]

    1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0
    """

let pgnGame = try PGNSerializer().game(from: pgnText)
let moves = pgnGame.mainlineMoves
let finalFEN = FENSerializer().fen(from: pgnGame.finalPosition)
let exported = try PGNSerializer().pgn(from: pgnGame)
```

Use `games(from:)` for PGN database text containing multiple games. FEN-backed
PGNs with `[SetUp "1"]` and `[FEN "..."]` are supported. Comments, including
Lichess clock and evaluation comments, and numeric annotation glyphs are
preserved on move records. Recursive annotation variations are intentionally
reported as unsupported until ChessCore has a public move-tree model.

`PGNGame.finalStatus` reports the replayed final status. PGN import and export
reject result markers that contradict terminal statuses ChessCore can prove,
while still accepting external decisive or drawn results for ongoing positions.

For a ChessCore-only walkthrough, see
[Docs/ChessCoreTutorial.md](Docs/ChessCoreTutorial.md). For terminology, see
[Docs/ChessCoreGlossary.md](Docs/ChessCoreGlossary.md). For a runnable
ChessCore-only command-line example, see
[Examples/ChessCoreRecipes](Examples/ChessCoreRecipes).

## ChessUI Quick Start

Use `ChessUI` when you want a reusable SwiftUI board. The view reports moves;
your app decides whether to apply them, update state, ask an engine for a
reply, or reject the move.

For a fuller walkthrough of model ownership, move handling, promotion,
perspective, highlighting, read-only boards, pickers, evaluation bars, move
lists, status display, accessibility, and scope boundaries, see
[Docs/ChessUITutorial.md](Docs/ChessUITutorial.md).

![ChessBoardView rendering a starting chess position](Docs/Images/chessboard-starting-position.png)

```swift
import SwiftUI
import ChessCore
import ChessUI

private let startingFEN =
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

struct BoardDemoView: View {
    @State private var model = ChessBoardModel(
        fen: startingFEN,
        boardTheme: .artDecoMonochrome,
        pieceSet: .sashiteMerida
    )

    var body: some View {
        @Bindable var editableModel = model

        VStack {
            Picker("Pieces", selection: $editableModel.pieceSet) {
                ForEach(ChessPieceSet.availableSets) { pieceSet in
                    Text(pieceSet.displayName).tag(pieceSet)
                }
            }

            Picker("Board", selection: $editableModel.boardTheme) {
                ForEach(ChessBoardTheme.availableThemes) { boardTheme in
                    Text(boardTheme.displayName).tag(boardTheme)
                }
            }

            ChessBoardView(model: model)
                .onMove { attempt in
                    guard attempt.isLegal else { return }

                    model.game.apply(move: attempt.move)

                    let fen = FENSerializer().fen(from: model.game.position)
                    model.setFEN(fen, animatedMove: attempt.move)
                }
                .frame(width: 320, height: 320)
        }
    }
}
```

`Examples/ChessWorkbench` is the runnable integration example for these APIs.
`ChessBoardModel.setFEN(_:animatedMove:)` returns `false` and records
`fenError` when a FEN update fails, leaving the current board unchanged.
ChessUI includes runtime registries for bundled piece sets and board themes.
Use `ChessPieceSet.availableSets` and `ChessBoardTheme.availableThemes` to build
pickers for the options bundled by the current package version.
Rank and file coordinate labels are shown by default; set
`ChessBoardModel.showsCoordinateLabels` to `false` for diagrams, training modes,
or app surfaces that provide their own coordinates.
Use `ChessBoardModel.interactionMode` to choose whether the board is read-only,
reports only legal moves, reports illegal attempts, or acts as a free setup
surface where either side's pieces can be dragged.

### Evaluation Bar

`ChessEvaluationBar` is a standalone SwiftUI view for app-provided evaluation
data. It is not tied to `ChessBoardView`; place it next to a board, above or
below a board, or in a separate layout region.

```swift
ChessEvaluationBar(
    evaluation: .centipawns(85),
    orientation: .vertical,
    whiteSide: .bottom,
    maximumCentipawns: 800
)
.frame(width: 28, height: 320)
```

Centipawn values are White-positive: `+100` means White is ahead by about one
pawn, `-100` means Black is ahead by about one pawn, and `0` is equal. Forced
mate values use the side that is delivering mate:

```swift
ChessEvaluationBar(evaluation: .mate(moves: 3, side: .white))
```

Apps that consume UCI engines such as Stockfish should parse and normalize
engine output before passing values into ChessUI. ChessUI only renders the
current value; it does not start an engine, run analysis, choose moves, or
interpret search output.

### Game Status

`ChessGameStatusView` renders caller-supplied `GameStatus` values from
`ChessCore` as compact app-friendly text. It does not own `Game`, compute
rules, apply moves, or decide app-specific endings such as resignation or
timeout.

```swift
ChessGameStatusView(
    status: game.status,
    turn: game.position.state.turn
) { claim in
    try? game.claimDraw(claim)
}
```

When `GameStatus.ongoing(drawClaims:)` contains claimable draw rules, the view
can render claim buttons and call back with `GameDrawClaim` values. Omit the
callback to show status text only.

### Move List

`ChessMoveListView` renders caller-supplied move records as a compact SAN move
list. Build the records from `ChessCore` moves so SAN is captured in the
correct pre-move position:

```swift
let startingPosition = try FENSerializer().position(from: startingFEN)
let records = try ChessMoveRecordBuilder().records(
    initialPosition: startingPosition,
    moves: game.moveHistory
)

ChessMoveListView(records: records, selectedPly: selectedPly) { record in
    selectedPly = record.ply
}
.frame(height: 160)
```

The default layout is vertical: full moves render as rows, with White and Black
shown on the same row. Give vertical lists a fixed height in the surrounding
layout. Populated vertical lists grow downward, then scroll inside that viewport
and follow the newest move as records are appended.

Use horizontal layout for a compact left-to-right move strip:

```swift
ChessMoveListView(
    records: records,
    selectedPly: selectedPly,
    layout: .horizontal,
    scrollIndicatorVisibility: .hidden
) { record in
    selectedPly = record.ply
}
.frame(height: 48)
```

Horizontal lists grow from the leading edge, then scroll horizontally once the
move strip exceeds its viewport.

Scroll indicators are consumer-controlled. The default is `.automatic`, which
uses the platform-standard behavior. Pass `.hidden` to keep the move list
scrollable without showing vertical or horizontal indicators:

```swift
ChessMoveListView(
    records: records,
    scrollIndicatorVisibility: .hidden
)
```

The move list is intentionally not a full PGN viewer. It does not render tag
pairs, comments, NAGs, variations, or game results (yet). Apps that need PGN
records should parse them with `ChessCore` and pass the move records they want
to display into ChessUI.

### Managing Piece Sets

Each bundled piece set is intentionally self-contained:

- one `ChessPieceSet` case,
- twelve prefixed image assets named `<setName>_wK`, `<setName>_wQ`,
  `<setName>_wR`, `<setName>_wB`, `<setName>_wN`, `<setName>_wP`,
  `<setName>_bK`, `<setName>_bQ`, `<setName>_bR`, `<setName>_bB`,
  `<setName>_bN`, and `<setName>_bP`,
- one piece-set snapshot reference named `piece-set-<setName>.png`.

To remove a bundled set, delete its enum case, delete its twelve prefixed
imagesets from `Sources/ChessUI/Assets/Pieces.xcassets`, remove its snapshot
reference, and refresh the ChessUI snapshots. Callers that use
`ChessPieceSet.availableSets` automatically stop presenting the removed set.

### Managing Board Themes

Each bundled board theme is intentionally self-contained:

- one `ChessBoardTheme` case,
- theme-provided square, label, selected, legal-move, hint, and last-move
  styling,
- optional lightweight texture rendering in `ChessBoardView`,
- one board-theme snapshot reference named `board-theme-<themeName>.png`.

To remove a bundled board theme, delete its enum case, remove any matching
texture rendering branch, remove its snapshot reference, and refresh the
ChessUI snapshots. Callers that use `ChessBoardTheme.availableThemes`
automatically stop presenting the removed theme.

## Scope

SwiftChessTools provides:

- Board state, pieces, moves, legal move generation, FEN, SAN, and PGN helpers.
- A reusable SwiftUI chessboard with selectable piece assets, selectable board
  themes, coordinate-label visibility, move interaction, highlighting, hints,
  promotion UI, and board perspective support.
- A standalone SwiftUI evaluation bar for caller-supplied centipawn, mate, or
  unavailable evaluation states.
- A compact SwiftUI move list for caller-supplied SAN move records.
- A compact SwiftUI game-status view for caller-supplied game status and
  optional draw-claim actions.
- A small macOS workbench and automated tests for package behavior.

SwiftChessTools does not provide:

- A chess engine, AI opponent, Stockfish integration, or analysis pipeline.
- Opening books, clocks, online play, accounts, or sync.

## Manual Workbench

`Examples/ChessWorkbench` is a small macOS SwiftUI app for manually exercising
`ChessCore` and `ChessUI` from inside this package. It renders a real
`ChessBoardView`, lets you edit the current FEN, applies legal board moves, and
exposes quick controls for reset, hints, board sizing, piece-set selection,
board-theme selection, coordinate-label visibility, move-list display,
game-status display, evaluation-bar samples, and promotion UI.

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
5. Confirm the move list records the move in SAN.
6. Confirm the status display updates the side to move.
7. Change the evaluation value, placement, and White side controls.
8. Try `Reset`, `Hint`, and `Show Promotion Picker`.

## Testing

See [Docs/ChessCoreTestingStrategy.md](Docs/ChessCoreTestingStrategy.md) for
the ChessCore correctness-corpus approach, including the current rule-engine and
game-state invariant coverage boundaries.

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

SwiftChessTools is MIT licensed and independent from the GPL-licensed
`StockfishEmbedded` sibling project.

This project draws significant inspiration from
[ChessKit](https://github.com/aperechnev/ChessKit) by Alexander Perechnev and
[ChessboardKit](https://github.com/rohanrhu/ChessboardKit) by Rohan R. H. U.
Early versions incorporate ideas and implementation approaches from those
projects. This repository is independent and is not affiliated with or endorsed
by the original maintainers.

See `NOTICE.md` for preserved MIT license notices and bundled asset provenance.
