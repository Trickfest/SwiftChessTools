//
//  RealGamesTests.swift
//  ChessCoreTests
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

@testable import ChessCore

@Test func game1() {
    let fenSerializer = FENSerializer()
    let moves = "g1h3 c7c6 h3g5 e7e5 g5e4 d7d5 d2d4".split(separator: " ").map { $0.description }

    let initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    let position = fenSerializer.position(from: initialFen)
    let game = Game(position: position)

    moves.forEach { game.apply(move: $0) }

    let finalFen = fenSerializer.fen(from: game.position)
    #expect(
        finalFen.split(separator: " ").first
            == "rnbqkbnr/pp3ppp/2p5/3pp3/3PN3/8/PPP1PPPP/RNBQKB1R b KQkq - 0 4".split(
                separator: " "
            ).first
    )
}

@Test func game2() {
    let fenSerializer = FENSerializer()
    let fen = "8/1p3p1k/4p3/3p4/6p1/1K6/8/2q5 w - - 0 52"
    let position = fenSerializer.position(from: fen)
    let game = Game(position: position)
    let legalMoves = game.legalMoves.map { $0.description }

    #expect(legalMoves.contains("b3b2") == false)
}
