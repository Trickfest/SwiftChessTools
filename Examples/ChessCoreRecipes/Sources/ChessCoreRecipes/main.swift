import ChessCore
import Darwin
import Foundation

let samplePGN = """
    [Event "Scholar's Mate"]
    [Site "?"]
    [Date "????.??.??"]
    [Round "?"]
    [White "White"]
    [Black "Black"]
    [Result "1-0"]

    1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0
    """

let pgnText = pgnInputOrSample()

let pgnSerializer = PGNSerializer()
let fenSerializer = FENSerializer()
let games = try pgnSerializer.games(from: pgnText)

print("Imported \(games.count) game(s)")

for (index, game) in games.enumerated() {
    let event = game.tagValue(for: "Event") ?? "?"
    let white = game.tagValue(for: "White") ?? "?"
    let black = game.tagValue(for: "Black") ?? "?"
    let finalFEN = fenSerializer.fen(from: game.finalPosition)

    print("")
    print("Game \(index + 1)")
    print("Event: \(event)")
    print("Players: \(white) vs \(black)")
    print("Result: \(game.result)")
    print("Final status: \(description(for: game.finalStatus))")
    print("Final FEN: \(finalFEN)")
    print("Moves:")

    for record in game.moveRecords {
        let prefix = record.color == .white
            ? "\(record.moveNumber)."
            : "\(record.moveNumber)..."
        print("  \(prefix) \(record.san) [\(record.move)]")
    }

    print("")
    print("Normalized PGN:")
    print(try pgnSerializer.pgn(from: game), terminator: "")
}

print("")
print("FEN validation:")

switch fenSerializer.validationResult(for: Position.standardStartingFEN) {
case .valid(let position):
    print("  Standard position is valid with \(position.board.enumeratedPieces().count) pieces.")
case .invalidSyntax(let error):
    print("  Syntax error: \(error.description)")
case .invalidPosition(let validation):
    print("  Semantic issues: \(validation.issues)")
}

let scratchGame = Game()
try scratchGame.applyLegal(move: "e2e4")
try scratchGame.applyLegal(move: "e7e5")

print("")
print("Safe move application:")
print("  After 1. e4 e5: \(fenSerializer.fen(from: scratchGame.position))")
print("  Status: \(description(for: scratchGame.status))")

func description(for status: GameStatus) -> String {
    switch status {
    case .ongoing(let drawClaims) where drawClaims.isEmpty:
        return "ongoing"
    case .ongoing(let drawClaims):
        return "ongoing, claimable draws: \(drawClaims.map(description(for:)).sorted().joined(separator: ", "))"
    case .checkmate(let winner):
        return "\(description(for: winner)) wins by checkmate"
    case .draw(let reason):
        return "draw by \(reason)"
    }
}

func description(for color: PieceColor) -> String {
    switch color {
    case .white:
        return "White"
    case .black:
        return "Black"
    }
}

func description(for claim: GameDrawClaim) -> String {
    switch claim {
    case .fiftyMoveRule:
        return "fifty-move rule"
    case .threefoldRepetition:
        return "threefold repetition"
    }
}

func pgnInputOrSample() -> String {
    guard isatty(STDIN_FILENO) == 0 else {
        return samplePGN
    }

    let inputData = FileHandle.standardInput.readDataToEndOfFile()
    let input = String(data: inputData, encoding: .utf8) ?? ""
    return input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? samplePGN
        : input
}
