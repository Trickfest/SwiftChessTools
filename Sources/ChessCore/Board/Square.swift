//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

/// A square on the board.
public struct Square: Hashable, Sendable {

    private(set) var index: Int
    let bitboardMask: Bitboard

    /// Zero-based file index, where `0` is file `a`.
    public var file: Int {
        self.index / Board.rankCoordinates.count
    }

    /// Zero-based rank index, where `0` is rank `1`.
    public var rank: Int {
        self.index % Board.fileCoordinates.count
    }

    /// Algebraic coordinate for the square, such as `"e4"`.
    public var coordinate: String {
        let file = Board.fileCoordinates[self.file]
        let rank = Board.rankCoordinates[self.rank]
        return "\(file)\(rank)"
    }

    /// `true` when the square is inside the board.
    private(set) var isValid: Bool

    // MARK: Initializers

    init(bitboardMask: Bitboard) {
        self.bitboardMask = bitboardMask
        self.index = 0
        self.isValid = bitboardMask > Int64.zero

        var mask = bitboardMask
        while mask > 1 {
            mask = mask >> 1
            self.index += 1
        }
    }

    /// Creates a square from its zero-based board index.
    public init(index: Int) {
        self.index = index
        self.bitboardMask = 1 << index
        self.isValid = (Int.zero..<Board.squaresCount).contains(self.index)
    }

    /// Creates a square from zero-based file and rank indexes.
    public init(file: Int, rank: Int) {
        self.init(index: file * Board.rankCoordinates.count + rank)
        self.isValid = (Int.zero...7).contains(file) && (Int.zero...7).contains(rank)
    }

    /// Creates a square from an algebraic coordinate such as `"e4"`.
    public init(coordinate: String) {
        let fileCharacter = coordinate.first ?? "-"
        let rankCharacter = coordinate.last ?? "-"

        let file = Board.fileCoordinates.firstIndex(of: fileCharacter) ?? -1
        let rank = Board.rankCoordinates.firstIndex(of: rankCharacter) ?? -1

        if file == -1 || rank == -1 {
            self.init(index: -1)
        } else {
            self.init(file: file, rank: rank)
        }
    }

    /// Returns the square reached by applying file and rank offsets.
    public func translate(file: Int, rank: Int) -> Square {
        return Square(file: self.file + file, rank: self.rank + rank)
    }

}

extension Square: CustomStringConvertible {

    /// Algebraic coordinate for the square.
    public var description: String {
        return self.coordinate
    }

}
