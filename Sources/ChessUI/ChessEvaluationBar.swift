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

/// Standalone SwiftUI evaluation bar for engine-provided chess evaluations.
///
/// The view only renders values supplied by the caller. It does not know about
/// Stockfish, analysis searches, move generation, or game playback.
public struct ChessEvaluationBar: View {
    private let evaluation: ChessEvaluation
    private let orientation: ChessEvaluationBarOrientation
    private let whiteSide: ChessEvaluationBarWhiteSide
    private let maximumCentipawns: Int
    private let showsLabel: Bool
    private let whiteColor: Color
    private let blackColor: Color
    private let borderColor: Color

    /// Creates a standalone evaluation bar.
    ///
    /// - Parameters:
    ///   - evaluation: White-positive centipawn, mate, or unavailable value.
    ///   - orientation: Main-axis direction for the bar.
    ///   - whiteSide: Edge the White portion grows from.
    ///   - maximumCentipawns: Centipawn score that visually saturates the bar.
    ///   - showsLabel: Shows a compact text label over the bar.
    ///   - whiteColor: Color used for the White segment.
    ///   - blackColor: Color used for the Black segment.
    ///   - borderColor: Color used for the bar outline.
    public init(
        evaluation: ChessEvaluation,
        orientation: ChessEvaluationBarOrientation = .vertical,
        whiteSide: ChessEvaluationBarWhiteSide = .bottom,
        maximumCentipawns: Int = ChessEvaluationBarDisplayState.defaultMaximumCentipawns,
        showsLabel: Bool = true,
        whiteColor: Color = Color(white: 0.96),
        blackColor: Color = Color(white: 0.12),
        borderColor: Color = Color.black.opacity(0.22)
    ) {
        self.evaluation = evaluation
        self.orientation = orientation
        self.whiteSide = whiteSide
        self.maximumCentipawns = maximumCentipawns
        self.showsLabel = showsLabel
        self.whiteColor = whiteColor
        self.blackColor = blackColor
        self.borderColor = borderColor
    }

    /// SwiftUI content for the evaluation bar.
    public var body: some View {
        let displayState = ChessEvaluationBarDisplayState(
            evaluation: evaluation,
            maximumCentipawns: maximumCentipawns
        )
        let resolvedWhiteSide = whiteSide.isCompatible(with: orientation)
            ? whiteSide
            : ChessEvaluationBarWhiteSide.defaultSide(for: orientation)

        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius(for: geometry.size))
                    .fill(blackColor)

                whiteSegment(
                    in: geometry.size,
                    displayState: displayState,
                    whiteSide: resolvedWhiteSide
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius(for: geometry.size)))

                if showsLabel {
                    label(displayState.label)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius(for: geometry.size))
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .frame(minWidth: minimumSize.width, minHeight: minimumSize.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Evaluation")
        .accessibilityValue(displayState.accessibilityValue)
        .accessibilityIdentifier("ChessUI.evaluationBar")
    }

    private var minimumSize: CGSize {
        switch orientation {
        case .vertical:
            CGSize(width: 22, height: 120)
        case .horizontal:
            CGSize(width: 120, height: 22)
        }
    }

    private func whiteSegment(
        in size: CGSize,
        displayState: ChessEvaluationBarDisplayState,
        whiteSide: ChessEvaluationBarWhiteSide
    ) -> some View {
        Rectangle()
            .fill(whiteColor)
            .frame(
                width: whiteSegmentWidth(in: size, fraction: displayState.whiteFraction),
                height: whiteSegmentHeight(in: size, fraction: displayState.whiteFraction)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: whiteSide))
    }

    private func whiteSegmentWidth(in size: CGSize, fraction: Double) -> CGFloat {
        switch orientation {
        case .vertical:
            size.width
        case .horizontal:
            size.width * CGFloat(fraction)
        }
    }

    private func whiteSegmentHeight(in size: CGSize, fraction: Double) -> CGFloat {
        switch orientation {
        case .vertical:
            size.height * CGFloat(fraction)
        case .horizontal:
            size.height
        }
    }

    private func alignment(for whiteSide: ChessEvaluationBarWhiteSide) -> Alignment {
        switch whiteSide {
        case .top:
            .top
        case .bottom:
            .bottom
        case .leading:
            .leading
        case .trailing:
            .trailing
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(.regularMaterial)
            }
            .accessibilityHidden(true)
    }

    private func cornerRadius(for size: CGSize) -> CGFloat {
        min(7, min(size.width, size.height) * 0.35)
    }
}
