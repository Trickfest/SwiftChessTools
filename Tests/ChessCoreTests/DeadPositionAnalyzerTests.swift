//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Testing

@testable import ChessCore

private struct DeadPositionFixture: Sendable {
    var name: String
    var fen: String
}

private let materialDeadPositionFixtures = [
    DeadPositionFixture(
        name: "Bare kings",
        fen: "8/8/8/8/8/8/8/K6k w - - 0 1"
    ),
    DeadPositionFixture(
        name: "White bishop versus bare king",
        fen: "8/8/8/8/8/8/8/KB5k w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Black knight versus bare king",
        fen: "k6n/8/8/8/8/8/8/K7 b - - 0 1"
    ),
    DeadPositionFixture(
        name: "Same-color bishops only",
        fen: "8/8/8/8/8/8/3b4/K1k1B1B1 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Same-color bishops across both sides",
        fen: "8/8/8/8/8/8/8/KBkB1b2 w - - 0 1"
    ),
]

@Test("Material-only dead positions remain insufficient-material draws", arguments: materialDeadPositionFixtures)
private func materialOnlyDeadPositionsRemainInsufficientMaterialDraws(testCase: DeadPositionFixture) throws {
    let position = try position(from: testCase.fen)
    let analyzer = DeadPositionAnalyzer()
    let game = Game(position: position)

    #expect(analyzer.hasInsufficientMatingMaterial(in: position), "\(testCase.name)")
    #expect(analyzer.isDeadPosition(position), "\(testCase.name)")
    #expect(game.status == .draw(.insufficientMaterial), "\(testCase.name)")
    #expect(game.outcome == .draw, "\(testCase.name)")
}

private let materialCanStillMateFixtures = [
    DeadPositionFixture(
        name: "Two knights can construct mate",
        fen: "8/8/8/8/8/8/8/KNN4k w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Opposite-color bishops can construct mate",
        fen: "8/8/8/8/8/8/8/KBk1b3 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Knight plus enemy blocker can construct mate",
        fen: "8/8/8/8/8/8/8/KNk2n2 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Pawn can promote into mating material",
        fen: "7k/P7/8/8/8/8/8/K7 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Rook is mating material",
        fen: "7k/8/8/8/8/8/8/KR6 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Queen is mating material",
        fen: "7k/8/8/8/8/8/8/KQ6 w - - 0 1"
    ),
]

@Test("Material that can still construct mate is not dead", arguments: materialCanStillMateFixtures)
private func materialThatCanStillConstructMateIsNotDead(testCase: DeadPositionFixture) throws {
    let position = try position(from: testCase.fen)
    let analyzer = DeadPositionAnalyzer()
    let game = Game(position: position)

    #expect(!analyzer.hasInsufficientMatingMaterial(in: position), "\(testCase.name)")
    #expect(!analyzer.isDeadPosition(position), "\(testCase.name)")
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()), "\(testCase.name)")
}

private let blockedDeadPositionFixtures = [
    DeadPositionFixture(
        name: "Sawtooth locked pawn barrier",
        fen: "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Sawtooth locked pawn barrier with black to move",
        fen: "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 b - - 0 1"
    ),
    DeadPositionFixture(
        name: "Locked barrier with trapped sliders",
        fen: "6rk/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/KQ6 w - - 0 1"
    ),
]

@Test("Blocked positions proven unreachable to mate are dead positions", arguments: blockedDeadPositionFixtures)
private func blockedPositionsProvenUnreachableToMateAreDeadPositions(testCase: DeadPositionFixture) throws {
    let position = try position(from: testCase.fen)
    let analyzer = DeadPositionAnalyzer()
    let game = Game(position: position)

    #expect(!analyzer.hasInsufficientMatingMaterial(in: position), "\(testCase.name)")
    #expect(analyzer.isDeadPosition(position), "\(testCase.name)")
    #expect(game.status == .draw(.deadPosition), "\(testCase.name)")
    #expect(game.outcome == .draw, "\(testCase.name)")
}

@Test("Dead-position proof is symmetric under board mirrors and color swaps", arguments: blockedDeadPositionFixtures)
private func deadPositionProofIsSymmetric(testCase: DeadPositionFixture) throws {
    let position = try position(from: testCase.fen)
    let analyzer = DeadPositionAnalyzer()
    let fileMirror = position.mirroredFiles()
    let colorSwap = position.rotatedAndColorSwapped()

    #expect(analyzer.isDeadPosition(fileMirror), "\(testCase.name), file mirror")
    #expect(Game(position: fileMirror).status == .draw(.deadPosition), "\(testCase.name), file mirror")
    #expect(analyzer.isDeadPosition(colorSwap), "\(testCase.name), color swap")
    #expect(Game(position: colorSwap).status == .draw(.deadPosition), "\(testCase.name), color swap")
}

private let blockedNearMissFixtures = [
    DeadPositionFixture(
        name: "Gap creates a legal pawn advance",
        fen: "7k/8/8/8/1p1p1p2/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "Diagonal contact creates a legal pawn capture",
        fen: "7k/8/8/8/1p1p1p1p/1PpPpPpP/P1P1P1P1/K7 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "A knight can still jump the barrier",
        fen: "6rk/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/KN6 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "A bishop can capture a barrier pawn",
        fen: "6bk/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K1B5 w - - 0 1"
    ),
    DeadPositionFixture(
        name: "An opposing king-side component contains attacking material",
        fen: "6Bk/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"
    ),
]

@Test("Blocked near-misses are not false-positive dead positions", arguments: blockedNearMissFixtures)
private func blockedNearMissesAreNotFalsePositiveDeadPositions(testCase: DeadPositionFixture) throws {
    let position = try position(from: testCase.fen)
    let analyzer = DeadPositionAnalyzer()
    let game = Game(position: position)

    #expect(!analyzer.isDeadPosition(position), "\(testCase.name)")
    #expect(game.status == .ongoing(drawClaims: Set<GameDrawClaim>()), "\(testCase.name)")
}

@Test func sealedPawnBarrierProofDoesNotDependOnReachabilityBudget() throws {
    let position = try position(
        from: "7k/8/8/8/1p1p1p1p/pPpPpPpP/P1P1P1P1/K7 w - - 0 1"
    )

    #expect(DeadPositionAnalyzer(maximumReachabilityNodes: 0).isDeadPosition(position))
    #expect(DeadPositionAnalyzer(maximumReachabilityNodes: 100_000).isDeadPosition(position))
}

@Test func deadPositionThatIsAlreadyStalemateKeepsStalemateStatusPrecedence() throws {
    let position = try position(
        from: "7k/5K2/6B1/8/8/8/8/8 b - - 0 1"
    )

    #expect(DeadPositionAnalyzer().isDeadPosition(position))
    #expect(Game(position: position).status == .draw(.stalemate))
}

private func position(from fen: String) throws -> Position {
    return try FENSerializer().position(from: fen)
}

private extension Position {
    func mirroredFiles() -> Position {
        return self.mapSquares(transformSquare: { square in
            Square(file: 7 - square.file, rank: square.rank)
        }, transformPiece: { $0 }, transformTurn: { $0 })
    }

    func rotatedAndColorSwapped() -> Position {
        return self.mapSquares(transformSquare: { square in
            Square(file: 7 - square.file, rank: 7 - square.rank)
        }, transformPiece: { piece in
            Piece(kind: piece.kind, color: piece.color.opposite)
        }, transformTurn: { $0.opposite })
    }

    private func mapSquares(
        transformSquare: (Square) -> Square,
        transformPiece: (Piece) -> Piece,
        transformTurn: (PieceColor) -> PieceColor
    ) -> Position {
        var board = Board()
        for (square, piece) in self.board.enumeratedPieces() {
            board[transformSquare(square)] = transformPiece(piece)
        }

        return Position(
            board: board,
            state: Position.State(
                turn: transformTurn(self.state.turn),
                castlingRights: [],
                enPassant: nil
            ),
            counter: self.counter
        )
    }
}
