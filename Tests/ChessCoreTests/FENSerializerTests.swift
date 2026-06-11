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
    "FEN serialization",
    arguments: [
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "r1bqkbnr/pppp1ppp/2n5/8/2BpP3/5N2/PPP2PPP/RNBQK2R b KQkq - 1 4",
        "r1b1r1k1/pp1nbppp/1q2pn2/2ppN3/3P1B2/2PBPQ2/PP1N1PPP/1R2K2R b K - 4 10",
        "rnbqkbnr/pp2pppp/8/2ppP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3",
        "8/8/8/8/4K3/8/8/8 w - - 0 1",
    ])
func serialization(fen: String) {
    let serializer = FENSerializer()
    let position = try! serializer.position(from: fen)
    #expect(fen == serializer.fen(from: position))
}

@Test(
    "FEN parsing failures are reported",
    arguments: [
        ("", FENParsingError.invalidFieldCount(expected: 6, actual: 1)),
        (
            "8/8/8/8/8/8/8 w - - 0 1",
            FENParsingError.invalidPiecePlacement("8/8/8/8/8/8/8")
        ),
        (
            "8/8/8/8/8/8/8/8 x - - 0 1",
            FENParsingError.invalidActiveColor("x")
        ),
        (
            "8/8/8/8/8/8/8/8 w KKK - 0 1",
            FENParsingError.invalidCastlingRights("KKK")
        ),
        (
            "8/8/8/8/8/8/8/8 w - e4 0 1",
            FENParsingError.invalidEnPassantSquare("e4")
        ),
        (
            "8/8/8/8/8/8/8/8 w - - -1 1",
            FENParsingError.invalidHalfmoveClock("-1")
        ),
        (
            "8/8/8/8/8/8/8/8 w - - 0 0",
            FENParsingError.invalidFullmoveNumber("0")
        ),
    ])
func parsingFailure(fen: String, expectedError: FENParsingError) {
    do {
        _ = try FENSerializer().position(from: fen)
        Issue.record("Expected FEN parsing to fail for: \(fen)")
    } catch let error as FENParsingError {
        #expect(error == expectedError)
    } catch {
        Issue.record("Expected FENParsingError, got: \(error)")
    }
}
