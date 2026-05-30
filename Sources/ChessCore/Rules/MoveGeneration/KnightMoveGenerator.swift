//
//  KnightMoveGenerator.swift
//  ChessCore
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

class KnightMoveGenerator: StepMoveGenerator {

    init() {
        super.init(offsets: MoveOffsets().knight)
    }

}
