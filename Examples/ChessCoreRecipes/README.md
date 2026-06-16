# ChessCoreRecipes

This is a small ChessCore-only command-line example. It demonstrates:

- parsing one or more PGN games
- reading tags and validated move records
- printing final FEN and final status
- exporting deterministic normalized PGN
- validating FEN with non-throwing diagnostics
- safely applying coordinate moves with `Game.applyLegal(move:)`

Run the bundled sample from the SwiftChessTools package root:

```sh
swift run --package-path Examples/ChessCoreRecipes
```

When standard input is an interactive terminal, the example uses its bundled
sample PGN instead of waiting for input.

Pipe your own PGN into the example:

```sh
cat game.pgn | swift run --package-path Examples/ChessCoreRecipes
```

The example has no SwiftUI dependency. It imports `ChessCore` only.
