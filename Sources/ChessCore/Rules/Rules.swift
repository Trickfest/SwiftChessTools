//
//  Rules.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

protocol Rules {
    func legalMovesForPiece(at square: Square, in position: Position) -> [Move]
    func legalMoves(in position: Position) -> [Move]
    func isCheck(in position: Position) -> Bool
    func isCheckmate(in position: Position) -> Bool
}
