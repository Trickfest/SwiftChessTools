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

@Test(
    "Position validator accepts semantically playable FENs",
    arguments: [
        PGNSerializer.standardStartingFEN,
        "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1",
        "rnbqkbnr/pp2pppp/8/2ppP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3",
        "4k3/8/8/8/8/8/Q7/4K3 w - - 100 1",
        "QN6/8/8/8/8/8/8/k1K5 b - - 0 1",
        "K1k5/8/8/8/8/8/8/qn6 w - - 0 2",
        "n1bqkbnr/P1P1P1P1/8/8/8/8/p1p1p1p1/N1BQKBNR w - - 0 1",
        "4k3/8/8/8/3Pp3/8/8/4K3 b - d3 0 1",
    ])
func positionValidatorAcceptsPlayablePositions(fen: String) throws {
    let position = try FENSerializer().position(from: fen)

    #expect(PositionValidator().issues(in: position).isEmpty)
    #expect(try FENSerializer().validatedPosition(from: fen) == position)
}

@Test func positionValidatorReportsMissingAndMultipleKings() throws {
    expectValidationIssues(
        for: "8/8/8/8/8/8/8/8 w - - 0 1",
        [
            .missingKing(.white),
            .missingKing(.black),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/8/8/8/8/8/K3K3 w - - 0 1",
        [
            .multipleKings(.white, count: 2),
        ]
    )
}

@Test func positionValidatorReportsPawnsOnInvalidRanks() throws {
    expectValidationIssues(
        for: "P3k3/8/8/8/8/8/8/4K2p w - - 0 1",
        [
            .pawnOnInvalidRank(Square(coordinate: "a8")),
            .pawnOnInvalidRank(Square(coordinate: "h1")),
        ]
    )
}

@Test func positionValidatorReportsInvalidCastlingRights() throws {
    expectValidationIssues(
        for: "4k3/8/8/8/8/8/8/4K3 w K - 0 1",
        [
            .invalidCastlingRight(Piece(kind: .king, color: .white)),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/8/8/8/8/8/4K2r w K - 0 1",
        [
            .invalidCastlingRight(Piece(kind: .king, color: .white)),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/8/8/8/8/8/4K3 b q - 0 1",
        [
            .invalidCastlingRight(Piece(kind: .queen, color: .black)),
        ]
    )

    expectValidationIssues(
        for: "n3k2r/8/8/8/8/8/8/N3K2R w KQkq - 0 1",
        [
            .invalidCastlingRight(Piece(kind: .queen, color: .white)),
            .invalidCastlingRight(Piece(kind: .queen, color: .black)),
        ]
    )
}

@Test func positionValidatorReportsInvalidEnPassantTargets() throws {
    expectValidationIssues(
        for: "4k3/8/8/3p4/8/8/4P3/4K3 w - d6 0 1",
        [
            .invalidEnPassantTarget(Square(coordinate: "d6")),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/3n4/3pP3/8/8/8/4K3 w - d6 0 1",
        [
            .invalidEnPassantTarget(Square(coordinate: "d6")),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/8/r4pPK/8/8/8/8 w - f6 0 1",
        [
            .invalidEnPassantTarget(Square(coordinate: "f6")),
        ]
    )

    expectValidationIssues(
        for: "8/8/8/8/R4Ppk/8/8/4K3 b - f3 0 1",
        [
            .invalidEnPassantTarget(Square(coordinate: "f3")),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/8/3pP3/8/8/8/4K3 w - d6 1 1",
        [
            .invalidEnPassantTarget(Square(coordinate: "d6")),
        ]
    )

    expectValidationIssues(
        for: "4k3/8/8/8/3Pp3/8/8/4K3 b - d3 1 1",
        [
            .invalidEnPassantTarget(Square(coordinate: "d3")),
        ]
    )
}

@Test func positionValidatorReportsInactiveSideInCheck() throws {
    expectValidationIssues(
        for: "4k3/8/8/8/8/8/4Q3/4K3 w - - 0 1",
        [
            .inactiveKingInCheck(.black),
        ]
    )

    expectValidationIssues(
        for: "4k3/4q3/8/8/8/8/8/4K3 b - - 0 1",
        [
            .inactiveKingInCheck(.white),
        ]
    )

    expectValidationIssues(
        for: "8/8/8/8/4k3/4K3/8/8 w - - 0 1",
        [
            .inactiveKingInCheck(.black),
        ]
    )

    expectValidationIssues(
        for: "8/8/8/8/4k3/4K3/8/8 b - - 0 1",
        [
            .inactiveKingInCheck(.white),
        ]
    )
}

@Test func positionValidatorReportsMultipleIndependentIssues() throws {
    expectValidationIssues(
        for: "P3k3/8/8/8/8/8/8/8 w K d6 1 1",
        [
            .missingKing(.white),
            .pawnOnInvalidRank(Square(coordinate: "a8")),
            .invalidCastlingRight(Piece(kind: .king, color: .white)),
            .invalidEnPassantTarget(Square(coordinate: "d6")),
        ]
    )
}

@Test func fenValidatedPositionPreservesSyntaxErrorsAndThrowsSemanticErrors() throws {
    do {
        _ = try FENSerializer().validatedPosition(from: "8/8/8/8/8/8/8 w - - 0 1")
        Issue.record("Expected syntax-invalid FEN to throw")
    } catch let error as FENParsingError {
        #expect(error == .invalidPiecePlacement("8/8/8/8/8/8/8"))
    } catch {
        Issue.record("Expected FENParsingError, got: \(error)")
    }

    do {
        _ = try FENSerializer().validatedPosition(from: "8/8/8/8/8/8/8/8 w - - 0 1")
        Issue.record("Expected semantically invalid FEN to throw")
    } catch let error as PositionValidationError {
        if case let .invalidPosition(issues) = error {
            #expect(issues.contains(.missingKing(.white)))
            #expect(issues.contains(.missingKing(.black)))
        } else {
            Issue.record("Expected invalidPosition, got: \(error)")
        }
    } catch {
        Issue.record("Expected PositionValidationError, got: \(error)")
    }
}

private func expectValidationIssues(
    for fen: String,
    _ expectedIssues: [PositionValidationIssue]
) {
    let position = try! FENSerializer().position(from: fen)
    let issues = PositionValidator().issues(in: position)

    #expect(issues.count == expectedIssues.count)
    for expectedIssue in expectedIssues {
        #expect(issues.contains(expectedIssue), "Expected \(expectedIssue) in \(issues)")
    }

    do {
        _ = try FENSerializer().validatedPosition(from: fen)
        Issue.record("Expected semantic validation to fail for: \(fen)")
    } catch let error as PositionValidationError {
        #expect(error == .invalidPosition(issues))
    } catch {
        Issue.record("Expected PositionValidationError, got: \(error)")
    }
}
