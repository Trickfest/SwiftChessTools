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
2. Linear game timeline and historical-position navigation. *(Implemented.)*
3. Typed PGN comment directives.
4. Public game tree and recursive PGN variations.
5. Annotated variation UI and richer board annotations.
6. Per-set piece rendering scale overrides. *(Implemented in 1.3.0.)*
7. Consumer-defined board appearance and piece artwork.
8. Public chess-service API clients, beginning with Lichess.

The sequence is only a starting point. Completed capabilities are summarized
here for context; the tutorials and changelog own their API details and history.

## Implemented: External Coordinate Labels

External labels are implemented with ranks on the left and files below the
board, flush top/right edges, and an unchanged outer frame. Inside labels remain
the source-compatible default. The feature originated in
[GitHub issue #1](https://github.com/Trickfest/SwiftChessTools/issues/1).
[SwiftChessDemo](https://github.com/Trickfest/SwiftChessDemo) demonstrates
None / Inside / Outside controls. See the ChessUI tutorial for usage.

## Study And Game-Record Foundations

### Implemented: Linear Game Timeline And Navigation

`ChessCore.GameTimeline` validates a linear move sequence, caches SAN records,
reconstructs independent games at ply zero through the recorded end, and
supports atomic append or explicit continuation replacement. Reconstruction
preserves repetition, move counters, castling, en passant, and rules-derived
status. Actual draw claims, resignation, and other explicit outcomes remain
app-owned; they cannot be inferred from moves alone.

`ChessUI.ChessMoveNavigationView` reports start/previous/next/end intent;
`ChessMoveListView` supports direct selection and opt-in selected-move scrolling.
`ChessBoardModel.setGame(_:)` installs an independent full game for display.
The consuming app owns the cursor, editing policy, engine authority, and storage.
Existing clients retain their prior defaults without adopting these APIs.

ChessWorkbench demonstrates editable linear exploration.
[SwiftChessDemo](https://github.com/Trickfest/SwiftChessDemo) demonstrates
read-only history browsing alongside a separate authoritative live game in
both gameplay modes. See the ChessCore and ChessUI tutorials for API examples.

This is not a variation tree or a generalized undo manager. Apps decide whether
to preserve a future line, replace it, or prohibit editing. Recursive variations
and the public game-tree model below remain future work.

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

### Implemented: Per-Set Piece Rendering Scale Overrides

Board-local overrides preserve bundled defaults and scale stationary, dragged,
animated, and promotion artwork consistently without changing square hit targets.
Finite values clamp to `0.50...1.00`; nonfinite values restore defaults.
ChessWorkbench and both SwiftChessDemo gameplay modes demonstrate a per-set
slider and default reset. See the ChessUI tutorial for the public API.

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

### Lichess And Public Chess-Service API Clients

Explore a maintained Swift interface to public chess services, beginning with
Lichess and potentially adding the read-only Chess.com Published-Data API.
The initial inspiration is
[navanchauhan/swift-lichess](https://swiftpackageindex.com/navanchauhan/swift-lichess),
which demonstrates broad typed coverage, OAuth with PKCE, and NDJSON streaming.
Its current Swift Package Index record shows a September 2025 update, twelve
direct and transitive dependencies, and no detected license, so it should be
treated as design inspiration rather than copied or adopted without a separate
licensing and maintenance review.

The service surface is large and changes on a different cadence from chess
rules and UI. The preferred design should therefore evaluate a companion
package or optional products such as `LichessAPI` and `ChessComAPI` instead of
adding networking responsibilities to `ChessCore`, `ChessUI`, or `ChessUCI`.
Provider-specific models should remain distinct unless a genuinely stable
shared abstraction emerges.

Possible staged scope:

- Start with useful unauthenticated, read-only operations such as profiles,
  ratings, game export, broadcasts, puzzles, opening exploration, and public
  archives.
- Add Lichess OAuth 2 with PKCE and caller-managed token storage without ever
  persisting credentials inside the package.
- Provide typed `AsyncSequence` support for Lichess NDJSON event and game
  streams, cancellation, reconnect boundaries, and incremental decoding.
- Add authenticated challenges, board play, studies, tournaments, or bot
  operations only after a concrete application needs them.
- Treat Chess.com's current PubAPI as a separate read-only provider; honor its
  JSON-LD responses, cache headers, and user-agent guidance instead of implying
  feature parity with Lichess.

Maintenance and quality requirements:

- Use the official Lichess OpenAPI specification and official Chess.com API
  documentation as the source of truth, recording the upstream schema revision
  used for each release.
- Keep any code generation reproducible and reviewed, with a small handwritten
  Swift facade that presents stable names and isolates upstream schema churn.
- Prefer Swift concurrency and an injectable `URLSession`-style transport so
  tests can use recorded fixtures without contacting live services.
- Model HTTP, decoding, authentication, cancellation, cache, and rate-limit
  failures explicitly. Lichess currently advises one request at a time and a
  full one-minute pause after HTTP 429 responses.
- Avoid unnecessary dependencies, require Swift 6 concurrency safety, redact
  authorization data from diagnostics, and never make live network access part
  of the deterministic local test gate.
- Review each provider's terms, attribution, branding, and rate-limit rules
  before release, and document which endpoints are intentionally unsupported.

The goal would be a dependable Apple-platform client maintained alongside the
rest of the chess workspace, not a promise to mirror every endpoint immediately
or a provider-neutral online-play framework.

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

### Additional Display Components

Consider captured-piece panels, material-balance widgets, opening-book displays,
and a full PGN viewer for tags, comments, NAGs, variations, and results. These
should render caller-supplied data and report intent, leaving analysis and
product-specific game banners or training policy to consumers. Variation UI
depends on the game-tree foundation above; probing and engine integration belong
in dedicated adapters rather than ChessCore or ChessUI.

## Ideas To Keep Outside SwiftChessTools

Unless the package direction changes explicitly, the following remain better
owned by applications or dedicated engine wrappers:

- Bundled chess engines or a built-in minimax opponent.
- UCI process management, engine lifecycle, option policy, or search
  orchestration.
- App-owned online-play flows, account presentation, matchmaking policy, or
  sync. A narrowly scoped transport client may live in an optional product or
  companion package, but it should not move those product decisions into the
  shared chess rules or UI layers.
- Product-specific training, grading, entitlement, persistence, or navigation
  flows.
