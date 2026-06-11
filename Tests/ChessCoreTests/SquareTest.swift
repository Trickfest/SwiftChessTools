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

@Test func initWithIndex() {
    for index in 0..<64 {
        let square = Square(index: index)
        #expect(square.index == index)
        #expect(square.isValid == true)
    }
}

@Test func initWithFileAndRank() {
    for file in 0...7 {
        for rank in 0...7 {
            let square = Square(file: file, rank: rank)
            #expect(file == square.file)
            #expect(rank == square.rank)
        }
    }
}

@Test func initWithCoordinate() {
    #expect(Square(coordinate: "a1") == Square(file: 0, rank: 0))
    #expect(Square(coordinate: "e4") == Square(file: 4, rank: 3))
    #expect(Square(coordinate: "h8") == Square(file: 7, rank: 7))

    #expect(Square(coordinate: "").isValid == false)
    #expect(Square(coordinate: "z9").isValid == false)
}

@Test func gettingCoordinate() {
    let coordinates = ["a1", "e4", "d5", "h8"]

    for coordinate in coordinates {
        let square = Square(coordinate: coordinate)

        #expect(square.coordinate == coordinate)
        #expect("\(square)" == coordinate)
    }
}

@Test func squareTranslation() {
    let e4Square = Square(coordinate: "e4")
    #expect(e4Square.translate(file: -1, rank: 1).coordinate == "d5")
}
