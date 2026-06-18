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

/// Built-in visual themes for ChessUI boards.
///
/// Use `availableThemes` to build app pickers without hard-coding the package's
/// current theme list.
public enum ChessBoardTheme: String, CaseIterable, Identifiable, Sendable {
    /// Ivory and tournament green squares.
    case classicGreen

    /// Cream and walnut-toned wood squares.
    case warmWalnut

    /// Quiet blue-gray analysis-board colors.
    case blueStudy

    /// Pale stone squares with subtle marble veining.
    case marble

    /// Drafting-board squares with fine blueprint grid marks.
    case blueprint

    /// Monochrome geometric board styling.
    case artDecoMonochrome

    /// Graphite circuit-board styling with restrained trace marks.
    case circuitBoard

    /// Hardwood sports-court styling with subtle court-line accents.
    case sportsCourt

    /// Stable identifier for picker and list usage.
    public var id: String { rawValue }

    /// Built-in themes currently bundled with ChessUI.
    ///
    /// The order is intended for picker display and may expand as new bundled
    /// board themes are added.
    public static var availableThemes: [ChessBoardTheme] {
        Array(allCases)
    }

    /// Human-readable name suitable for pickers and settings.
    public var displayName: String {
        switch self {
        case .classicGreen:
            "Classic Green"
        case .warmWalnut:
            "Warm Walnut"
        case .blueStudy:
            "Blue Study"
        case .marble:
            "Marble"
        case .blueprint:
            "Blueprint"
        case .artDecoMonochrome:
            "Art Deco Monochrome"
        case .circuitBoard:
            "Circuit Board"
        case .sportsCourt:
            "Sports Court"
        }
    }

    var lightSquare: Color {
        switch self {
        case .classicGreen:
            Color(red: 0.94, green: 0.92, blue: 0.82)
        case .warmWalnut:
            Color(red: 0.91, green: 0.78, blue: 0.57)
        case .blueStudy:
            Color(red: 0.84, green: 0.89, blue: 0.93)
        case .marble:
            Color(red: 0.90, green: 0.89, blue: 0.86)
        case .blueprint:
            Color(red: 0.79, green: 0.88, blue: 0.95)
        case .artDecoMonochrome:
            Color(red: 0.91, green: 0.91, blue: 0.89)
        case .circuitBoard:
            Color(red: 0.67, green: 0.73, blue: 0.69)
        case .sportsCourt:
            Color(red: 0.88, green: 0.68, blue: 0.42)
        }
    }

    var darkSquare: Color {
        switch self {
        case .classicGreen:
            Color(red: 0.39, green: 0.58, blue: 0.41)
        case .warmWalnut:
            Color(red: 0.55, green: 0.35, blue: 0.18)
        case .blueStudy:
            Color(red: 0.36, green: 0.50, blue: 0.63)
        case .marble:
            Color(red: 0.55, green: 0.56, blue: 0.57)
        case .blueprint:
            Color(red: 0.25, green: 0.45, blue: 0.63)
        case .artDecoMonochrome:
            Color(red: 0.67, green: 0.67, blue: 0.65)
        case .circuitBoard:
            Color(red: 0.20, green: 0.28, blue: 0.25)
        case .sportsCourt:
            Color(red: 0.55, green: 0.31, blue: 0.14)
        }
    }

    var label: Color {
        switch self {
        case .circuitBoard, .blueprint:
            Color.white.opacity(0.82)
        case .warmWalnut, .sportsCourt:
            Color(red: 0.16, green: 0.10, blue: 0.06).opacity(0.78)
        default:
            Color.black.opacity(0.66)
        }
    }

    var selected: Color {
        switch self {
        case .circuitBoard:
            Color(red: 0.56, green: 0.95, blue: 0.76)
        case .blueprint:
            Color.white.opacity(0.92)
        default:
            Color(red: 0.13, green: 0.48, blue: 0.88)
        }
    }

    var hinted: Color {
        switch self {
        case .circuitBoard:
            Color(red: 0.96, green: 0.72, blue: 0.34)
        case .blueprint:
            Color(red: 0.98, green: 0.75, blue: 0.34)
        default:
            Color(red: 0.77, green: 0.22, blue: 0.18)
        }
    }

    var legalMove: Color {
        switch self {
        case .circuitBoard:
            Color(red: 0.46, green: 0.95, blue: 0.72, opacity: 0.48)
        case .blueprint:
            Color.white.opacity(0.48)
        case .sportsCourt:
            Color(red: 0.13, green: 0.17, blue: 0.22, opacity: 0.34)
        default:
            Color.black.opacity(0.34)
        }
    }

    var lastMoveHighlight: Color {
        switch self {
        case .circuitBoard:
            Color(red: 0.44, green: 0.95, blue: 0.78, opacity: 0.38)
        case .blueprint:
            Color.white.opacity(0.34)
        case .artDecoMonochrome:
            Color(red: 0.98, green: 0.91, blue: 0.52, opacity: 0.48)
        default:
            Color(red: 1.0, green: 0.82, blue: 0.20, opacity: 0.50)
        }
    }

    var texture: ChessBoardTexture {
        switch self {
        case .classicGreen, .blueStudy:
            .none
        case .warmWalnut:
            .wood
        case .marble:
            .marble
        case .blueprint:
            .blueprint
        case .artDecoMonochrome:
            .artDeco
        case .circuitBoard:
            .circuit
        case .sportsCourt:
            .sportsCourt
        }
    }
}

enum ChessBoardTexture: Sendable {
    case none
    case wood
    case marble
    case blueprint
    case artDeco
    case circuit
    case sportsCourt
}
