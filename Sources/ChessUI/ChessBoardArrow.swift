//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import SwiftUI

/// Visual styling for a board arrow rendered by `ChessBoardView`.
///
/// Styles are display-only. They do not carry engine semantics; apps decide
/// what an arrow means before passing it to ChessUI.
///
/// ```swift
/// model.arrows = [
///     ChessBoardArrow(from: "e2", to: "e4", style: .primarySuggestion)
/// ].compactMap { $0 }
/// ```
public struct ChessBoardArrowStyle: Equatable, Sendable {
    /// Red component from `0` through `1`.
    public var red: Double

    /// Green component from `0` through `1`.
    public var green: Double

    /// Blue component from `0` through `1`.
    public var blue: Double

    /// Requested stroke width in points.
    public var lineWidth: CGFloat

    /// Arrow opacity from `0` through `1`.
    public var opacity: Double

    /// Arrow color before opacity is applied.
    public var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    /// Creates an arrow style.
    ///
    /// Component and opacity values are clamped into display ranges. Line
    /// widths smaller than one point are raised to one point.
    public init(red: Double, green: Double, blue: Double, lineWidth: CGFloat = 7, opacity: Double = 0.76) {
        self.red = Self.clamped(red)
        self.green = Self.clamped(green)
        self.blue = Self.clamped(blue)
        self.lineWidth = max(1, lineWidth)
        self.opacity = min(1, max(0, opacity))
    }

    /// Strongest built-in suggestion style, intended for the primary move.
    public static let primarySuggestion = ChessBoardArrowStyle(
        red: 0.10,
        green: 0.43,
        blue: 0.92,
        lineWidth: 9,
        opacity: 0.82
    )

    /// Medium built-in suggestion style, intended for the second move.
    public static let secondarySuggestion = ChessBoardArrowStyle(
        red: 0.94,
        green: 0.54,
        blue: 0.12,
        lineWidth: 7,
        opacity: 0.72
    )

    /// Subtle built-in suggestion style, intended for the third move.
    public static let tertiarySuggestion = ChessBoardArrowStyle(
        red: 0.10,
        green: 0.58,
        blue: 0.42,
        lineWidth: 4.5,
        opacity: 0.66
    )

    /// General-purpose annotation style for non-ranked arrows.
    public static let annotation = ChessBoardArrowStyle(
        red: 0.76,
        green: 0.18,
        blue: 0.14,
        lineWidth: 6,
        opacity: 0.72
    )

    private static func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

/// A board arrow from one square to another.
///
/// ChessUI renders arrows supplied by the app. It does not compute, rank, or
/// validate suggested moves.
///
/// Use the built-in suggestion styles for ranked app-supplied moves, or pass a
/// custom `ChessBoardArrowStyle` for study annotations.
public struct ChessBoardArrow: Sendable {
    /// Source square for the arrow.
    public var from: BoardSquare

    /// Target square for the arrow.
    public var to: BoardSquare

    /// Visual style used to render the arrow.
    public var style: ChessBoardArrowStyle

    /// Optional accessibility label override.
    public var label: String?

    /// Creates a board arrow from two board squares.
    public init(
        from: BoardSquare,
        to: BoardSquare,
        style: ChessBoardArrowStyle = .annotation,
        label: String? = nil
    ) {
        self.from = from
        self.to = to
        self.style = style
        self.label = label
    }

    /// Creates a board arrow from algebraic coordinate strings such as `e2`.
    ///
    /// Returns `nil` when either coordinate is not on the board.
    public init?(
        from sourceSquare: String,
        to targetSquare: String,
        style: ChessBoardArrowStyle = .annotation,
        label: String? = nil
    ) {
        guard let from = Self.square(from: sourceSquare),
              let to = Self.square(from: targetSquare)
        else {
            return nil
        }

        self.init(from: from, to: to, style: style, label: label)
    }

    private static func square(from coordinate: String) -> BoardSquare? {
        let characters = Array(coordinate.lowercased())
        guard characters.count == 2 else { return nil }

        guard let column = Array("abcdefgh").firstIndex(of: characters[0]),
              let rank = Int(String(characters[1])),
              (1...8).contains(rank)
        else {
            return nil
        }

        return BoardSquare(row: rank - 1, column: column)
    }
}
