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
import SwiftUI

/// Normalized display data used by `ChessGameStatusView`.
///
/// Use this type directly when you need ChessUI's compact status text outside a
/// SwiftUI view.
public struct ChessGameStatusDisplayState: Equatable, Sendable {
    /// Compact text describing the supplied game status.
    public let text: String

    /// Accessibility value describing the supplied game status.
    public let accessibilityValue: String

    /// Claimable draw rules in deterministic display order.
    public let drawClaims: [GameDrawClaim]

    /// Creates display data for a `GameStatus`.
    ///
    /// - Parameters:
    ///   - status: Current status supplied by ChessCore or the caller.
    ///   - turn: Side to move. Used only for ongoing statuses.
    public init(status: GameStatus, turn: PieceColor? = nil) {
        switch status {
        case let .ongoing(claims):
            drawClaims = Self.orderedDrawClaims(from: claims)
            text = Self.ongoingText(turn: turn, drawClaims: drawClaims)

        case let .checkmate(winner):
            drawClaims = []
            text = "\(Self.colorName(winner)) wins by checkmate"

        case let .draw(reason):
            drawClaims = []
            text = "Draw by \(Self.drawReasonName(reason))"
        }

        accessibilityValue = text
    }

    /// User-facing button label for a draw-claim action.
    public static func drawClaimButtonLabel(for claim: GameDrawClaim) -> String {
        switch claim {
        case .fiftyMoveRule:
            return "Claim fifty-move draw"
        case .threefoldRepetition:
            return "Claim threefold repetition draw"
        }
    }

    private static func orderedDrawClaims(from claims: Set<GameDrawClaim>) -> [GameDrawClaim] {
        [.fiftyMoveRule, .threefoldRepetition].filter { claims.contains($0) }
    }

    private static func ongoingText(turn: PieceColor?, drawClaims: [GameDrawClaim]) -> String {
        let baseText = turn.map { "\(colorName($0)) to move" } ?? "Game ongoing"

        guard !drawClaims.isEmpty else {
            return baseText
        }

        let claimText = drawClaims.map(drawClaimName).joinedForDisplay()
        let claimPrefix = drawClaims.count == 1
            ? "Draw claim available"
            : "Draw claims available"

        return "\(baseText). \(claimPrefix): \(claimText)"
    }

    private static func colorName(_ color: PieceColor) -> String {
        switch color {
        case .white:
            return "White"
        case .black:
            return "Black"
        }
    }

    private static func drawClaimName(_ claim: GameDrawClaim) -> String {
        switch claim {
        case .fiftyMoveRule:
            return "fifty-move rule"
        case .threefoldRepetition:
            return "threefold repetition"
        }
    }

    private static func drawReasonName(_ reason: GameDrawReason) -> String {
        switch reason {
        case .stalemate:
            return "stalemate"
        case .insufficientMaterial:
            return "insufficient material"
        case .deadPosition:
            return "dead position"
        case .seventyFiveMoveRule:
            return "seventy-five-move rule"
        case .fivefoldRepetition:
            return "fivefold repetition"
        case .fiftyMoveRule:
            return "fifty-move rule"
        case .threefoldRepetition:
            return "threefold repetition"
        }
    }
}

/// Standalone SwiftUI status view for ChessCore game status values.
///
/// The view only renders caller-supplied status data. It does not own `Game`,
/// apply moves, compute legal rules, parse notation, or decide app-specific
/// endings such as resignation, timeout, or adjudication.
///
/// ```swift
/// ChessGameStatusView(status: game.status, turn: game.position.state.turn) {
///     try? game.claimDraw($0)
/// }
/// ```
public struct ChessGameStatusView: View {
    private let status: GameStatus
    private let turn: PieceColor?
    private let onDrawClaim: ((GameDrawClaim) -> Void)?

    /// Creates a display-only game status view.
    ///
    /// - Parameters:
    ///   - status: Current status supplied by ChessCore or the caller.
    ///   - turn: Side to move. Used only for ongoing statuses.
    ///   - onDrawClaim: Optional callback for claimable draw actions.
    public init(
        status: GameStatus,
        turn: PieceColor? = nil,
        onDrawClaim: ((GameDrawClaim) -> Void)? = nil
    ) {
        self.status = status
        self.turn = turn
        self.onDrawClaim = onDrawClaim
    }

    /// SwiftUI content for the status text and optional draw-claim controls.
    public var body: some View {
        let displayState = ChessGameStatusDisplayState(status: status, turn: turn)

        VStack(alignment: .leading, spacing: 8) {
            Text(displayState.text)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ChessUI.gameStatus.text")

            if let onDrawClaim, !displayState.drawClaims.isEmpty {
                drawClaimControls(
                    for: displayState.drawClaims,
                    onDrawClaim: onDrawClaim
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game status")
        .accessibilityValue(displayState.accessibilityValue)
        .accessibilityIdentifier("ChessUI.gameStatus")
    }

    private func drawClaimControls(
        for claims: [GameDrawClaim],
        onDrawClaim: @escaping (GameDrawClaim) -> Void
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(claims, id: \.self) { claim in
                    drawClaimButton(for: claim, onDrawClaim: onDrawClaim)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(claims, id: \.self) { claim in
                    drawClaimButton(for: claim, onDrawClaim: onDrawClaim)
                }
            }
        }
    }

    private func drawClaimButton(
        for claim: GameDrawClaim,
        onDrawClaim: @escaping (GameDrawClaim) -> Void
    ) -> some View {
        Button {
            onDrawClaim(claim)
        } label: {
            Text(ChessGameStatusDisplayState.drawClaimButtonLabel(for: claim))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityIdentifier("ChessUI.gameStatus.claim.\(claim.accessibilityIdentifierSuffix)")
    }
}

private extension Array where Element == String {
    func joinedForDisplay() -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return self[0]
        case 2:
            return "\(self[0]) and \(self[1])"
        default:
            return "\(dropLast().joined(separator: ", ")), and \(self[count - 1])"
        }
    }
}

private extension GameDrawClaim {
    var accessibilityIdentifierSuffix: String {
        switch self {
        case .fiftyMoveRule:
            return "fiftyMoveRule"
        case .threefoldRepetition:
            return "threefoldRepetition"
        }
    }
}
