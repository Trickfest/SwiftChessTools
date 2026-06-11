//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import Foundation

class Rays {

    private(set) var orthogonal = [Bitboard: Bitboard]()

    init() {
        for index in Bitboard.zero..<64 {
            let key: Bitboard = 0b1 << index
            let value: Bitboard = 0x0101_0101_0101_0101 << (index % 8) | 0xFF << (index / 8 * 8)
            self.orthogonal[key] = value
        }
    }

    func path(between s1: UInt8, and s2: UInt8) -> UInt8 {
        return s1 > s2 ? s1 - 2 * s2 : s2 - 2 * s1
    }

}
