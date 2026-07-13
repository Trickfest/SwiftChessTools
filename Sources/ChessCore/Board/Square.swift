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
///
/// `Square` stores zero-based file and rank indexes and formats itself as an
/// algebraic coordinate. Invalid inputs create an invalid square internally;
/// public APIs that parse user input usually validate before applying moves.
///
/// ```swift
/// let e4 = Square(coordinate: "e4")
/// print(e4.file) // 4
/// print(e4.rank) // 3
/// ```
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
    ///
    /// Invalid squares return `"-"` instead of trapping. Check `isValid` when
    /// accepting coordinates or indexes from outside the package.
    public var coordinate: String {
        guard isValid else { return "-" }
        let file = Board.fileCoordinates[self.file]
        let rank = Board.rankCoordinates[self.rank]
        return "\(file)\(rank)"
    }

    /// `true` when the square is inside the board.
    public private(set) var isValid: Bool

    // MARK: Initializers

    init(bitboardMask: Bitboard) {
        self.bitboardMask = bitboardMask
        let mask = bitboardMask
        guard mask != 0 else {
            self.index = -1
            self.isValid = false
            return
        }

        self.index = (UInt64.bitWidth - 1) - mask.leadingZeroBitCount
        self.isValid = true
    }

    /// Creates a square from its zero-based board index.
    ///
    /// Use this initializer when you are already working with board storage
    /// indexes. For app-facing code, `init(coordinate:)` is usually clearer.
    public init(index: Int) {
        self.index = index
        self.isValid = (Int.zero..<Board.squaresCount).contains(self.index)
        self.bitboardMask = self.isValid ? Bitboard(1) << index : Bitboard.zero
    }

    /// Creates a square from zero-based file and rank indexes.
    ///
    /// Files and ranks are both `0...7`; file `0` is `a`, and rank `0` is
    /// rank `1`.
    public init(file: Int, rank: Int) {
        guard (Int.zero...7).contains(file), (Int.zero...7).contains(rank) else {
            self.init(index: -1)
            return
        }

        self.init(index: file * Board.rankCoordinates.count + rank)
    }

    /// Creates a square from an algebraic coordinate such as `"e4"`.
    ///
    /// Coordinate parsing is case-sensitive and expects a file in `a...h` and
    /// a rank in `1...8`.
    public init(coordinate: String) {
        guard coordinate.count == 2 else {
            self.init(index: -1)
            return
        }

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
        guard isValid else { return Square(index: -1) }

        let (translatedFile, fileOverflow) = self.file.addingReportingOverflow(file)
        let (translatedRank, rankOverflow) = self.rank.addingReportingOverflow(rank)
        guard !fileOverflow, !rankOverflow else { return Square(index: -1) }

        return Square(file: translatedFile, rank: translatedRank)
    }

}

extension Square: CustomStringConvertible {

    /// Algebraic coordinate for the square.
    public var description: String {
        return self.coordinate
    }

}
