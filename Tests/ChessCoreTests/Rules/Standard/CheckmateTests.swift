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

@Test func check() throws {
    let fenSerializer = FENSerializer()
    let positions: [String] = [
        "r3R2k/8/1R4Q1/8/7p/7P/6PK/8 b - - 0 42"
    ]

    positions.forEach {
        let position = try! fenSerializer.position(from: $0)
        let game = Game(position: position)

        #expect(game.isCheck == true)
        #expect(game.isCheckmate == false)
    }
}
