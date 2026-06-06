//
//  MoveTests.swift
//  ChessCoreTests
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

@testable import ChessCore

@Test func initWithSquares() {
    #expect(
        Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e4")).description == "e2e4"
    )

    #expect(
        Move(
            from: Square(coordinate: "d7"), to: Square(coordinate: "d8"),
            promotion: PieceKind.queen
        ).description == "d7d8q"
    )
}

@Test func initWithString() {
    #expect(try! Move(string: "e2e4").description == "e2e4")
    #expect(try! Move(string: "f7f8r").description == "f7f8r")
}

@Test(
    "Coordinate move parsing failures are reported",
    arguments: [
        ("e2e", MoveParsingError.invalidLength("e2e")),
        ("i2e4", MoveParsingError.invalidSourceSquare("i2")),
        ("e2i4", MoveParsingError.invalidDestinationSquare("i4")),
        ("e7e8k", MoveParsingError.invalidPromotion("k")),
    ])
func initWithInvalidString(move: String, expectedError: MoveParsingError) {
    do {
        _ = try Move(string: move)
        Issue.record("Expected move parsing to fail for: \(move)")
    } catch let error as MoveParsingError {
        #expect(error == expectedError)
    } catch {
        Issue.record("Expected MoveParsingError, got: \(error)")
    }
}
