//
// ChessUI provides reusable SwiftUI chess board views and supporting helpers.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import ChessCore

/// Engine-style position evaluation data rendered by ChessUI components.
///
/// ChessUI treats centipawn scores as White-positive: positive values favor
/// White, negative values favor Black, and zero is equal. Apps that consume UCI
/// engines should normalize raw engine scores before passing them to ChessUI.
public enum ChessEvaluation: Equatable, Sendable {
    /// Centipawn score where `100` is one pawn and positive values favor White.
    case centipawns(Int)

    /// Forced mate in `moves` moves for `side`.
    case mate(moves: Int, side: PieceColor)

    /// No evaluation is currently available.
    case unavailable
}

/// Main-axis orientation for `ChessEvaluationBar`.
public enum ChessEvaluationBarOrientation: String, CaseIterable, Identifiable, Sendable {
    /// Vertical bar, usually placed to the leading or trailing side of a board.
    case vertical

    /// Horizontal bar, usually placed above or below a board.
    case horizontal

    public var id: String { rawValue }

    /// Human-readable name suitable for pickers and settings.
    public var displayName: String {
        switch self {
        case .vertical:
            "Vertical"
        case .horizontal:
            "Horizontal"
        }
    }
}

/// Position of the White side within an evaluation bar.
public enum ChessEvaluationBarWhiteSide: String, CaseIterable, Identifiable, Sendable {
    /// White advantage fills from the top edge.
    case top

    /// White advantage fills from the bottom edge.
    case bottom

    /// White advantage fills from the leading edge.
    case leading

    /// White advantage fills from the trailing edge.
    case trailing

    public var id: String { rawValue }

    /// Human-readable name suitable for pickers and settings.
    public var displayName: String {
        switch self {
        case .top:
            "White at top"
        case .bottom:
            "White at bottom"
        case .leading:
            "White at leading"
        case .trailing:
            "White at trailing"
        }
    }

    /// Returns `true` when this side is meaningful for `orientation`.
    public func isCompatible(with orientation: ChessEvaluationBarOrientation) -> Bool {
        switch (self, orientation) {
        case (.top, .vertical), (.bottom, .vertical):
            true
        case (.leading, .horizontal), (.trailing, .horizontal):
            true
        default:
            false
        }
    }

    /// Default White side for `orientation`.
    public static func defaultSide(for orientation: ChessEvaluationBarOrientation) -> Self {
        switch orientation {
        case .vertical:
            .bottom
        case .horizontal:
            .leading
        }
    }
}

/// Normalized display data used by `ChessEvaluationBar`.
public struct ChessEvaluationBarDisplayState: Equatable, Sendable {
    /// Default centipawn value that maps to a full White or Black bar.
    public static let defaultMaximumCentipawns = 800

    /// Fraction of the bar filled by White, clamped to `0...1`.
    public let whiteFraction: Double

    /// Compact display label such as `+0.8`, `-1.4`, `M3`, or `--`.
    public let label: String

    /// Accessibility value describing the same state in words.
    public let accessibilityValue: String

    /// Creates normalized display data for an engine-style evaluation.
    ///
    /// - Parameters:
    ///   - evaluation: White-positive centipawn, mate, or unavailable value.
    ///   - maximumCentipawns: Centipawn score that visually saturates the bar.
    public init(
        evaluation: ChessEvaluation,
        maximumCentipawns: Int = Self.defaultMaximumCentipawns
    ) {
        let safeMaximumCentipawns = max(1, maximumCentipawns)

        switch evaluation {
        case .centipawns(let centipawns):
            let clampedCentipawns = min(max(centipawns, -safeMaximumCentipawns), safeMaximumCentipawns)
            whiteFraction = 0.5 + (Double(clampedCentipawns) / Double(safeMaximumCentipawns)) * 0.5
            label = Self.centipawnLabel(for: centipawns)
            accessibilityValue = Self.centipawnAccessibilityValue(for: centipawns)

        case .mate(let moves, let side):
            let moveCount = max(1, abs(moves))
            switch side {
            case .white:
                whiteFraction = 1
                label = "M\(moveCount)"
                accessibilityValue = "White mate in \(moveCount)"
            case .black:
                whiteFraction = 0
                label = "-M\(moveCount)"
                accessibilityValue = "Black mate in \(moveCount)"
            }

        case .unavailable:
            whiteFraction = 0.5
            label = "--"
            accessibilityValue = "Evaluation unavailable"
        }
    }

    private static func centipawnLabel(for centipawns: Int) -> String {
        let roundedTenths = Int((Double(abs(centipawns)) / 10).rounded())
        let pawns = "\(roundedTenths / 10).\(roundedTenths % 10)"

        if centipawns > 0 {
            return "+\(pawns)"
        }

        if centipawns < 0 {
            return "-\(pawns)"
        }

        return "0.0"
    }

    private static func centipawnAccessibilityValue(for centipawns: Int) -> String {
        let label = unsignedCentipawnLabel(for: abs(centipawns))

        if centipawns > 0 {
            return "White advantage \(label) pawns"
        }

        if centipawns < 0 {
            return "Black advantage \(label) pawns"
        }

        return "Equal evaluation"
    }

    private static func unsignedCentipawnLabel(for centipawns: Int) -> String {
        let roundedTenths = Int((Double(centipawns) / 10).rounded())
        return "\(roundedTenths / 10).\(roundedTenths % 10)"
    }
}
