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

@Test func testCross() {
    let rays = Rays()
    #expect(rays.orthogonal[0x0001]! == Bitboard(0x0101_0101_0101_01FF))
    #expect(rays.orthogonal[0x0800]! == Bitboard(0x0808_0808_0808_FF08))
    #expect(rays.orthogonal[0x8000]! == Bitboard(0x8080_8080_8080_FF80))
    #expect(rays.orthogonal[0x8000_0000_0000_0000]! == Bitboard(0xFF80_8080_8080_8080))
}

@Test func testPathBetween() {
    let rays = Rays()
    let s1: UInt8 = 0b01000000
    let s2: UInt8 = 0b00000010
    let r: UInt8 = 0b00111100

    #expect(rays.path(between: s1, and: s2) == r)
}
