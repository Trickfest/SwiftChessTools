//
//  PublicAPITests.swift
//  ChessCoreTests
//
//  Copyright © 2026 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

import ChessCore

@Test func serializationTypesArePubliclyInitializable() {
    _ = FENSerializer()
    _ = SANSerializer()
}

@Test func parserAPIsArePubliclyUsable() {
    let position = try! FENSerializer().position(
        from: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)
    let move = try! Move(string: "e2e4")

    #expect(SANSerializer().san(for: move, in: game) == "e4")
    #expect(FENParsingError.invalidFieldCount(expected: 6, actual: 1).description.isEmpty == false)
    #expect(MoveParsingError.invalidLength("e2").description.isEmpty == false)
    #expect(SANParsingError.emptySAN.description.isEmpty == false)
}
