# Possible Enhancements

This document collects possible future enhancements for SwiftChessTools. It is
an idea backlog, not a committed roadmap, release promise, or implementation
order. Before starting an item, confirm that a consuming app or package user
benefits from it and turn the idea into a narrower design with acceptance
criteria.

## Design Principles

- Keep reusable chess rules, position models, notation, and game-record
  behavior in `ChessCore`.
- Keep `ChessUI` display-focused and consumer-controlled. Views may report
  user intent, but the consuming app should continue to own game flow,
  playback policy, analysis, and persistence.
- Keep `ChessUCI` focused on typed command formatting and output parsing rather
  than engine process management or search orchestration.
- Preserve source compatibility when practical, especially for the current
  `Game`, `PGNGame`, and `ChessBoardModel` APIs.
- Prefer additive, independently useful foundations over a single large
  analysis or study feature.
- Require focused tests, public API documentation, tutorial updates, and
  Workbench or harness coverage appropriate to every implemented item.

## Suggested Sequence

The following sequence would produce useful increments while allowing the
larger study model to develop carefully:

1. External coordinate-label placement. *(Implemented.)*
2. Linear game timeline and historical-position navigation.
3. Typed PGN comment directives.
4. Public game tree and recursive PGN variations.
5. Annotated variation UI and richer board annotations.
6. Consumer-defined board appearance and piece artwork.

The sequence is only a starting point. External coordinates are independent of
the study features and can be implemented whenever convenient.

## Implemented: External Coordinate Labels

Source: [GitHub issue #1, External coordinates](https://github.com/Trickfest/SwiftChessTools/issues/1),
opened by Josh McKinney on August 21, 2026.

Before this work, the board showed file and rank coordinates inside its edge
squares or hid them entirely. The issue requests a configuration that can
place those coordinates outside the board, similar to the presentation in
[imihaly/ChessBoard](https://github.com/imihaly/ChessBoard).

Selected first scope:

- Add `ChessBoardCoordinateLabelPlacement` with `inside` and `outside` values,
  while retaining `showsCoordinateLabels` as the separate visibility control.
- Preserve the current inside-label presentation as the compatibility default.
- Keep file and rank ordering correct for both White and Black perspectives.
- Keep the total `ChessBoardView` frame unchanged and shrink the playable 8×8
  surface predictably to make room for the external gutters.
- Retain readable contrast without requiring every existing board theme to
  provide a second coordinate palette.
- Cover compact board sizes, Dynamic Type, VoiceOver, iPhone, iPad, and Mac.
- Add Workbench controls and snapshot or UI coverage for inside, outside, and
  hidden labels from both perspectives.

The implementation uses dark external gutters modeled on the issue's visual
reference, with ranks at the left and files at the bottom while the top and
right edges remain flush. The existing public initializer remains available
with its original signature, and a distinct initializer overload accepts an
explicit placement. Model, layout, public-API, snapshot, Workbench, and iOS
harness coverage protects the new behavior, while the existing inside-label
path remains the compatibility default. More detailed edge selection should be
added only if there is a demonstrated use case.

The issue discussion also mentions interest in more complex arrows and
annotations. Those are related analysis features, but they should remain
separate from the small coordinate-placement change. The reporter later noted
that there is no longer an immediate dependency on this change, so the issue is
a useful design request rather than an urgent compatibility blocker.

## Study And Game-Record Foundations

### Linear Game Timeline And Navigation

Provide a reusable representation of a game's main line that can answer what
the board looked like at any ply without requiring each application to write
its own replay loop.

Possible capabilities:

- Position, move record, and game status at ply zero through the final ply.
- Previous, next, start, end, and direct-ply navigation.
- Safe undo and redo semantics for applications that want reversible play.
- Correct reconstruction of repetition counts, draw claims, move counters,
  castling rights, and en-passant state.
- A consumer-owned cursor that can drive `ChessBoardView` and
  `ChessMoveListView` without moving playback policy into `ChessUI`.

The timeline should be designed as the linear main-line view of a future game
tree rather than as a competing history abstraction.

### Public Game Tree And Recursive PGN Variations

Add the public move-tree model that `Docs/PGN.md` already identifies as the
prerequisite for recursive annotation variations.

Possible node data:

- Stable node identity and parent-child relationships.
- The concrete move, canonical SAN, source SAN, move number, color, and ply.
- Comments, numeric annotation glyphs, and typed annotations.
- Main-line ordering plus any number of recursive variations.
- The resulting position and game status, either stored or reproducibly
  derived.

`PGNSerializer` could then accept and export recursive annotation variations
instead of reporting `unsupportedRecursiveVariation`. Existing flat main-line
access should remain available for compatibility and simple consumers.

This foundation would support annotated-game viewers, opening studies, puzzle
explanations, imported analysis, and richer training applications without
embedding any chess engine in SwiftChessTools.

### Annotated Move And Variation UI

Once the core tree model is stable, add display components that can show:

- Main-line moves and nested variations.
- The selected node and its comments or annotations.
- Navigation callbacks that let the application update its board.
- Compact and expanded layouts appropriate to iPhone, iPad, and Mac.
- Accessible descriptions and navigation for variation branches.

This should be a sibling or extension of `ChessMoveListView`, not a monolithic
view that owns a `Game`, parses PGN, or decides which variation to promote.

## Typed PGN Comment Directives

ChessCore currently preserves Lichess-style comment content such as `%eval`,
`%clk`, `%emt`, `%cal`, and `%csl` as raw comments. Add optional typed views of
these directives while retaining the original comment text for deterministic
round trips.

Potential typed values include:

- Centipawn and mate evaluations.
- Clock time and elapsed move time.
- Colored arrows.
- Colored square highlights.
- Unknown directives that remain preserved rather than rejected.

The core annotation types should use chess concepts such as squares, colors,
and evaluations without depending on SwiftUI. `ChessUI` can separately map
those values into board arrows, square marks, and evaluation displays.

## ChessUI Presentation And Interaction

### Richer Board Annotations

Generalize the current app-supplied arrow support into a small annotation
model. Possible marks include arrows, circles, outlined squares, filled square
highlights, colors, line styles, opacity, ordering, and accessibility labels.

Rendering app-supplied annotations is the first priority. Opt-in user gestures
for creating or removing annotations could follow, with callbacks reporting
intent to the application instead of silently owning the annotation document.

### Consumer-Defined Appearance And Piece Artwork

The current `ChessBoardTheme` and `ChessPieceSet` enums provide useful bundled
presets but do not let package consumers define a fully custom presentation.

Possible additions:

- A public value-based board appearance containing square, coordinate,
  selection, hint, legal-move, last-move, and annotation styling.
- Optional consumer-provided textures or square backgrounds.
- A piece-artwork provider that can resolve images from the consuming app's
  asset catalog or bundle.
- Continued support for every bundled theme and piece set as a convenient
  preset.

Extensibility should come before adding many more built-in visual sets.

### Position Editor

Build on `ChessBoardInteractionMode.freeSetup` with reusable editor primitives:

- Place, replace, move, and remove pieces.
- Select the side to move, castling rights, en-passant target, and move
  counters.
- Clear, reset, mirror, or rotate a position.
- Validate the resulting `Position` and export FEN.
- Report editing actions to the consumer so persistence remains app-owned.

A complete editor view could follow only after the underlying mutation and
validation model is useful independently of SwiftUI.

### Premoves And Pending-Move Display

Allow an application to display and collect a pending move while another side
or engine is thinking. ChessUI should report premove intent and render a
caller-supplied pending move; the application should decide when to revalidate,
apply, replace, or cancel it.

## Developer And Portability Capabilities

### Public Perft And Divide Utilities

Promote the repository's private perft test helper into a small public
diagnostic API that can return total node counts and per-root-move divide
results. This would help engine-wrapper authors and other rules
implementations compare move-generation behavior without duplicating the
recursive harness.

### EPD Support

Add Extended Position Description parsing and serialization for position test
suites, tactical collections, and engine diagnostics. Start with a deliberately
small set of well-defined operations rather than claiming every historical EPD
dialect.

### Official Non-UI Platform Support

Evaluate officially supporting `ChessCore` and `ChessUCI` on Linux and Windows
while keeping `ChessUI` Apple-only. This would require explicit build and test
evidence on each supported platform rather than relying on the absence of
Apple-framework imports in the two non-UI targets.

### Deeper Position Validation

Consider additional structural diagnostics for historically impossible
material counts and related FEN inconsistencies. These should remain
diagnostics rather than a claim that every accepted position is reachable from
the standard starting position.

### Broader Dead-Position Proofs

Expand `DeadPositionAnalyzer` only when additional cases can be proven without
false positives or unacceptable runtime cost. The current conservative result
is preferable to incorrectly declaring a playable position drawn.

## Later Ideas Requiring A Concrete Consumer

### Chess Clocks

A separate, deterministic clock model could describe sudden-death, increment,
or delay time controls while leaving scheduling, scene lifecycle, and timeout
policy to the app. This is broadly useful but orthogonal to the current package
and should wait for a real consumer.

### Chess960 And Other Variants

Chess960 would affect starting positions, castling rights, move generation,
FEN and PGN conventions, testing, and public rule abstractions. It should begin
only with a concrete product requirement and a complete compatibility design.
Other variants would require an even broader rules architecture and are not a
near-term extension of standard chess support.

### Static Diagram And Export Support

Consider a read-only diagram surface or rendering helper for widgets, teaching
material, and image or PDF export. This should reuse `ChessBoardView` styling
where practical and avoid adding a second rendering system that drifts from the
interactive board.

## Ideas To Keep Outside SwiftChessTools

Unless the package direction changes explicitly, the following remain better
owned by applications or dedicated engine wrappers:

- Bundled chess engines or a built-in minimax opponent.
- UCI process management, engine lifecycle, option policy, or search
  orchestration.
- Opening-database services, online play, accounts, matchmaking, or sync.
- Product-specific training, grading, entitlement, persistence, or navigation
  flows.
