//
//  CheckmateTests.swift
//  ChessCoreTests
//
//  Created by Alexander Perechnev, 2021.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

@testable import ChessCore

@Test func check() throws {
    let fenSerializer = FENSerializer()
    let positions: [String] = [
        "r3R2k/8/1R4Q1/8/7p/7P/6PK/8 b - - 0 42"
    ]

    positions.forEach {
        let position = fenSerializer.position(from: $0)
        let game = Game(position: position)

        #expect(game.isCheck == true)
        #expect(game.isCheckmate == false)
    }
}
