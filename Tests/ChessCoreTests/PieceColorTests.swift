//
//  PieceColorTests.swift
//  ChessCoreTests
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

import Testing

@testable import ChessCore

@Test func oppositeColor() {
    #expect(PieceColor.white == PieceColor.black.opposite)
    #expect(PieceColor.black == PieceColor.white.opposite)
}
