//
//  PositionTests.swift
//  ChessCoreTests
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

@testable import ChessCore

@Test func positionCopyIsIndependent() {
    let fenSerializer = FENSerializer()
    let initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    let position = fenSerializer.position(from: initialFen)

    var positionCopy = position
    positionCopy.board["e4"] = nil
    positionCopy.state.castlingRights = []
    positionCopy.state.enPassant = Square(coordinate: "e4")
    positionCopy.state.turn = .black
    positionCopy.counter.fullMoves = 100
    positionCopy.counter.halfMoves = 200

    #expect(fenSerializer.fen(from: position) == initialFen)
}
