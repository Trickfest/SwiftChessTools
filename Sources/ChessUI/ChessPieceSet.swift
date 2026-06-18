//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import ChessCore

/// Built-in chess piece artwork bundled with ChessUI.
public enum ChessPieceSet: String, CaseIterable, Identifiable, Sendable {
    /// Public-domain Merida-style pieces from Sashite.
    case sashiteMerida

    /// Original monochrome Art Deco pieces generated for SwiftChessTools.
    case artDecoMonochrome

    /// Original monochrome Brutalist pieces generated for SwiftChessTools.
    case brutalistMonochrome

    /// Original monochrome Origami pieces generated for SwiftChessTools.
    case origamiMonochrome

    /// Original monochrome Circuit Board pieces generated for SwiftChessTools.
    case circuitBoardMonochrome

    /// Original monochrome Blueprint pieces generated for SwiftChessTools.
    case blueprintMonochrome

    /// Original monochrome Sports pieces generated for SwiftChessTools.
    case sportsMonochrome

    /// Stable identifier for picker and list usage.
    public var id: String { rawValue }

    /// Built-in sets currently bundled with ChessUI.
    public static var availableSets: [ChessPieceSet] {
        Array(allCases)
    }

    /// Human-readable name suitable for pickers and settings.
    public var displayName: String {
        switch self {
        case .sashiteMerida:
            "Sashite Merida"
        case .artDecoMonochrome:
            "Art Deco Monochrome"
        case .brutalistMonochrome:
            "Brutalist Monochrome"
        case .origamiMonochrome:
            "Origami Monochrome"
        case .circuitBoardMonochrome:
            "Circuit Board Monochrome"
        case .blueprintMonochrome:
            "Blueprint Monochrome"
        case .sportsMonochrome:
            "Sports Monochrome"
        }
    }

    /// Name of the bundled image asset for `piece`.
    public func assetName(for piece: Piece) -> String {
        "\(rawValue)_\(pieceAssetCode(for: piece))"
    }

    /// All asset names required by this piece set.
    public var assetNames: [String] {
        Self.pieceAssetCodes.map { "\(rawValue)_\($0)" }
    }

    var imageInterpolation: ImageInterpolation {
        .high
    }

    static var bundledAssetNames: Set<String> {
        Set(Self.availableSets.flatMap(\.assetNames))
    }

    private func pieceAssetCode(for piece: Piece) -> String {
        let color = piece.color == .white ? "w" : "b"
        let kind: String
        switch piece.kind {
        case .king:
            kind = "K"
        case .queen:
            kind = "Q"
        case .rook:
            kind = "R"
        case .bishop:
            kind = "B"
        case .knight:
            kind = "N"
        case .pawn:
            kind = "P"
        }
        return "\(color)\(kind)"
    }

    private static let pieceAssetCodes = [
        "wK", "wQ", "wR", "wB", "wN", "wP",
        "bK", "bQ", "bR", "bB", "bN", "bP",
    ]
}

enum ImageInterpolation {
    case high
    case none
}
