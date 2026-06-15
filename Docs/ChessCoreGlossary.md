# ChessCore Glossary

This glossary defines the terms used by `ChessCore`, the ChessCore tutorial,
and the PGN documentation. It is intentionally ChessCore-focused: UI,
engine-analysis, and product-specific concepts belong in app-level docs.

## Package And API Terms

- **ChessCore**: The SwiftChessTools module for chess rules, game state,
  notation, and game-record parsing/export.
- **ChessUI**: The SwiftChessTools module for SwiftUI board display and UI
  components. ChessUI consumes ChessCore values; it should not own rules,
  notation, PGN parsing, or engine analysis.
- **Serializer**: A type that converts between ChessCore values and text
  formats. Examples include `FENSerializer`, `SANSerializer`, and
  `PGNSerializer`.
- **Parser Error**: A typed error thrown for malformed input or semantic
  validation failure. Examples include `FENParsingError`, `SANParsingError`,
  `MoveParsingError`, and `PGNParsingError`.
- **Position Validator**: `PositionValidator`, the ChessCore API that checks
  whether a syntactically parsed `Position` satisfies strict semantic position
  constraints.
- **Dead Position Analyzer**: `DeadPositionAnalyzer`, the ChessCore API that
  proves whether a position is dead because neither side can possibly
  checkmate.
- **Serialization Error**: A typed error thrown while exporting values, such as
  attempting to export an illegal concrete move list as PGN.
- **Sendable**: A Swift concurrency marker used by value types that can safely
  cross concurrency domains.

## Core Model Terms

- **Square**: A board coordinate such as `a1`, `e4`, or `h8`.
- **File**: A board column from `a` through `h`.
- **Rank**: A board row from `1` through `8`.
- **Piece Color**: The side a piece belongs to: White or Black.
- **Piece Kind**: The type of a piece: king, queen, rook, bishop, knight, or
  pawn.
- **Piece**: A piece kind and color, such as white queen or black knight.
- **Move**: A concrete coordinate move from one square to another, with an
  optional promotion piece.
- **Board**: Piece placement only. A board does not include side to move,
  castling rights, en passant target, or move counters.
- **Position**: A complete playable board state: board, side to move, castling
  rights, en passant target, halfmove clock, and fullmove number.
- **Game**: A playable wrapper around `Position` that applies moves, exposes
  legal moves, and tracks move history.
- **Game Status**: A high-level description of the current game state, exposed
  as `Game.status`.
- **Game Outcome**: The final result of a completed game: a win for one side or
  a draw.
- **Move History**: The concrete sequence of moves applied through `Game`.
- **Metadata-Only Move History**: Move history passed to
  `Game(position:moveHistory:)` or `reset(to:moveHistory:)` without replaying
  the moves. It is stored for consumers, but does not rebuild counters or
  repetition state.
- **Replay**: Reconstructing a `Game` by applying a concrete move list from an
  initial position, exposed as `Game.replay(initialPosition:moves:)`.
- **Reset**: Replacing a `Game` object's current position and derived state with
  `Game.reset(to:moveHistory:)`.
- **Initial Position**: The position before replaying a move list or PGN
  mainline. This is usually the standard starting position, but can come from a
  FEN tag.
- **Final Position**: The position after replaying all moves.
- **Final Status**: The `GameStatus` after replaying all moves in a game or PGN
  mainline. `PGNGame.finalStatus` stores this status for parsed and generated
  PGN records.
- **Standard Starting Position**: The normal chess starting position, represented
  by `PGNSerializer.standardStartingFEN`.

## Rule Terms

- **Legal Move**: A move allowed by chess rules from the current position.
- **Pseudo-Legal Move**: A move that follows piece movement rules before king
  safety is checked. This is mostly an internal move-generation concept.
- **Active Color**: The side whose turn it is to move.
- **Check**: A position where the active color's king is attacked.
- **Checkmate**: A check position where the active color has no legal moves.
- **Stalemate**: A non-check position where the active color has no legal moves.
- **Automatic Draw**: A draw that ends the game without a player claim, such as
  stalemate, insufficient material, dead position, the seventy-five-move rule,
  or fivefold repetition.
- **Draw Claim**: A draw rule available for a player to claim, such as the
  fifty-move rule or threefold repetition.
- **Claimed Draw**: A draw claim that has been applied with `Game.claimDraw`.
  Once claimed, `Game.status` reports a draw with the claimed reason.
- **Insufficient Material**: A material-only dead position where neither side
  has enough material to produce checkmate under ChessCore's standard
  insufficient-material model.
- **Dead Position**: A position where neither side can possibly checkmate by
  any legal sequence of moves. ChessCore reports material-only cases as
  `.draw(.insufficientMaterial)` and other proven cases as
  `.draw(.deadPosition)`.
- **Fifty-Move Rule**: A claimable draw when 100 halfmoves have passed without a
  pawn move or capture.
- **Seventy-Five-Move Rule**: An automatic draw when 150 halfmoves have passed
  without a pawn move or capture.
- **Threefold Repetition**: A claimable draw when the current repetition key has
  occurred at least three times.
- **Fivefold Repetition**: An automatic draw when the current repetition key has
  occurred at least five times.
- **Attack**: A square is attacked by a side if one of that side's pieces could
  capture a piece on that square according to chess movement rules.
- **King Safety**: The rule that a legal move may not leave or place the moving
  side's king in check.
- **Pin**: A piece is pinned when moving it would expose its king to attack.
- **Absolute Pin**: A pin against the king. The pinned piece may only move if
  the resulting position leaves the king safe.
- **Discovered Check**: A check revealed by moving a piece that had been
  blocking an attacking line.
- **Double Check**: A position where the king is attacked by two pieces at once.
  Only king moves can answer double check.
- **Castling**: The king-and-rook move that relocates the king two squares and
  moves the rook across it, subject to castling rights, empty path squares, and
  king-safety restrictions.
- **Castling Rights**: The remaining ability for either side to castle
  king-side or queen-side.
- **King-Side Castling**: Castling toward the `h` file, written `O-O` in SAN.
- **Queen-Side Castling**: Castling toward the `a` file, written `O-O-O` in SAN.
- **En Passant Target**: The square recorded after a two-square pawn advance
  that may allow an en passant capture on the next move.
- **En Passant Capture**: A pawn capture of a pawn that just advanced two
  squares, made as if the pawn had advanced one square.
- **Promotion**: Replacing a pawn with a queen, rook, bishop, or knight when the
  pawn reaches the last rank.
- **Underpromotion**: Promoting to a rook, bishop, or knight instead of a queen.

## Move Counting Terms

- **Ply**: One half-move. White's first move is ply 1, Black's reply is ply 2.
- **Move Number**: The full chess move number. White's and Black's first moves
  both have move number 1.
- **Halfmove Clock**: The FEN counter for halfmoves since the last pawn move or
  capture.
- **Fullmove Number**: The FEN move number, starting at 1 and incrementing after
  Black moves.
- **Position Count**: ChessCore currently tracks board occurrences by `Board`
  in `Game.positionCounts`.
- **Repetition Key**: The rules-relevant identity used for repetition claims:
  board layout, side to move, castling rights, and legal en-passant
  availability.
- **Current Repetition Count**: The number of times the current repetition key
  has appeared in a game.

## Notation Terms

- **Coordinate Move**: A move written with source and destination squares, such
  as `e2e4` or `e7e8q`.
- **UCI-Style Coordinate Notation**: The coordinate spelling used by
  `Move.description`, with promotion pieces normalized to lowercase, such as
  `e7e8q`.
- **FEN**: Forsyth-Edwards Notation, a text format for a single chess position.
- **Syntax-Only FEN Parsing**: `FENSerializer.position(from:)`, which checks
  FEN field syntax and returns a `Position`.
- **Semantic FEN Validation**: `FENSerializer.validatedPosition(from:)`, which
  parses FEN syntax and then rejects impossible or inconsistent positions such
  as missing kings, invalid castling rights, invalid en-passant targets,
  en-passant targets with a nonzero halfmove clock, pawns on invalid ranks, or
  inactive-side check.
- **SAN**: Standard Algebraic Notation, the human-readable move notation used in
  movetext, such as `Nf3`, `exd5`, `O-O`, or `Qxf7#`.
- **PGN**: Portable Game Notation, a text format for complete game records.
- **Source SAN**: The SAN token as it appeared in PGN source text after
  ChessCore's parser has removed symbolic annotation suffixes.
- **Canonical SAN**: SAN generated by `SANSerializer` after validating a move in
  context.
- **Disambiguation**: Extra file, rank, or square text in SAN that identifies
  which piece moved, such as `Nbd2` or `R1e2`.
- **Check Suffix**: The `+` suffix in SAN.
- **Checkmate Suffix**: The `#` suffix in SAN.

## FEN Terms

- **Piece Placement**: The first FEN field, listing each rank from 8 to 1.
- **Active Color Field**: The FEN field indicating whose turn it is, `w` or
  `b`.
- **Castling Availability Field**: The FEN field containing castling rights, or
  `-` when no side can castle.
- **En Passant Field**: The FEN field containing an en passant target square, or
  `-`.
- **Halfmove Field**: The FEN field containing the halfmove clock.
- **Fullmove Field**: The FEN field containing the fullmove number.

## PGN Terms

- **Tag Pair**: PGN metadata such as `[White "Fischer"]`.
- **Tag Name**: The identifier in a tag pair, such as `White`.
- **Tag Value**: The quoted string in a tag pair, such as `Fischer`.
- **Seven Tag Roster**: The standard PGN tags: `Event`, `Site`, `Date`,
  `Round`, `White`, `Black`, and `Result`.
- **Movetext**: The PGN move section after the tag pairs.
- **Mainline**: The primary sequence of moves in a PGN game.
- **Variation**: An alternate PGN line written in parentheses. First-pass
  ChessCore PGN support detects recursive variations but reports them as
  unsupported.
- **Comment**: Text annotation in a PGN game, usually written in braces or as a
  semicolon comment.
- **NAG**: Numeric Annotation Glyph, such as `$1`, used for move annotations.
- **Symbolic Annotation**: A shorthand annotation suffix such as `!`, `?`, `!?`,
  or `?!` in PGN movetext.
- **Result Marker**: One of `1-0`, `0-1`, `1/2-1/2`, or `*`.
- **Result/Status Conflict**: A PGN validation failure where replay reaches a
  terminal final status that is incompatible with the PGN result marker, such as
  checkmate for Black with a `1-0` result.
- **Validating PGN Export**: Export that replays a `PGNGame` model before
  writing text, rejecting inconsistent move records, final positions, final
  statuses, or result markers.
- **FEN-Backed PGN**: A PGN that starts from a non-standard position using
  `[SetUp "1"]` and `[FEN "..."]`.
- **PGN Database**: Text containing one or more PGN games.
- **UTF-8 BOM**: A byte-order marker that may appear at the start of a text
  file. ChessCore tolerates this marker at the start of PGN input.
- **Reduced Export Style**: PGN output that writes deterministic tags and
  movetext without trying to preserve the exact original whitespace.
- **Recursive Annotation Variation**: A PGN variation tree. ChessCore detects
  these in the first PGN milestone, but does not yet model them.

## Testing Terms

- **Perft**: A move-generation test that counts all legal move trees to a fixed
  depth from a known position.
- **Round Trip**: Serializing a value, parsing it back, and asserting the
  reparsed value is equivalent to the original.
- **Regression Test**: A test added for a bug so the same bug cannot silently
  return.
- **Synthetic Fixture**: A hand-authored position or game designed to test a
  specific rule or parser behavior.
- **Lichess Fixture**: Real-world PGN data from Lichess CC0 exports, used for
  redistributable corpus coverage.
- **Oracle**: An independent implementation or trusted data source used to
  confirm expected test values before adding them to ChessCore tests.
- **Coverage Matrix**: A planning table that classifies edge cases as already
  covered, worth adding next, future API work, or out of scope.

## Current Scope Notes

- **Standard Chess Only**: ChessCore currently targets standard chess rules, not
  Chess960 or other variants.
- **Mainline PGN First**: PGN support validates mainline games and preserves
  comments/NAGs, but does not yet model recursive variations.
- **Board-Based Position Counts**: `Game.positionCounts` tracks board
  occurrences by piece placement. Draw-claim repetition uses
  `Game.repetitionCounts` and `GameRepetitionKey` instead.
- **Dead Position Detection**: ChessCore proves material-only dead positions,
  sealed immobile pawn-barrier dead positions, and bounded legal-state
  reachability cases. The analyzer is conservative: positions outside those
  proven classes remain ongoing rather than risking a false-positive draw.
