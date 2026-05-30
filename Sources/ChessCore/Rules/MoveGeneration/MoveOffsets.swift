//
//  MoveOffsets.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

class MoveOffsets {

    private(set) lazy var diagonal = [
        (-1, -1), (1, 1), (-1, 1), (1, -1),
    ]
    private(set) lazy var orthogonal = [
        (-1, 0), (0, 1), (1, 0), (0, -1),
    ]
    private(set) lazy var allDirections = {
        self.orthogonal + self.diagonal
    }()
    private(set) lazy var knight = [
        (-2, 1), (-1, 2), (1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1),
    ]
    private(set) lazy var pawnCaptures = [
        (-1, 1), (1, 1),
    ]

}
