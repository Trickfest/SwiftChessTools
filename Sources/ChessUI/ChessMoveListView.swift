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

import ChessCore

/// Layout direction for `ChessMoveListView`.
public enum ChessMoveListLayout: String, CaseIterable, Hashable, Sendable {
    /// Renders full moves in rows and scrolls vertically.
    case vertical

    /// Renders full moves left-to-right and scrolls horizontally.
    case horizontal
}

/// Displays a compact, selectable list of game moves.
public struct ChessMoveListView: View {
    private static let moveRowMinimumHeight: CGFloat = 26
    private static let moveRowSpacing: CGFloat = 3
    private static let moveRowsVerticalPadding: CGFloat = 1
    private static let bottomAnchorID = "ChessUI.moveList.bottom"
    private static let horizontalGroupSpacing: CGFloat = 12
    private static let horizontalMoveSpacing: CGFloat = 6
    private static let horizontalGroupsHorizontalPadding: CGFloat = 1
    private static let trailingAnchorID = "ChessUI.moveList.trailing"
    private static let estimatedCharacterWidth: CGFloat = 8
    private static let estimatedMoveHorizontalPadding: CGFloat = 14
    private static let estimatedMoveNumberWidth: CGFloat = 30

    private let title: String?
    private let records: [ChessMoveRecord]
    private let selectedPly: Int?
    private let layout: ChessMoveListLayout
    private let scrollIndicatorVisibility: ScrollIndicatorVisibility
    private let onSelectRecord: ((ChessMoveRecord) -> Void)?

    /// Creates a move-list view.
    ///
    /// Pass records that already contain SAN and move numbering. `ChessUI`
    /// renders the supplied data; it does not parse PGN or own game history. To
    /// keep a stable viewport, constrain the view with a fixed size in the
    /// scrolling direction. Vertical content grows from the top until it
    /// exceeds the viewport, then scrolls to the newest move. Horizontal
    /// content grows from the leading edge until it exceeds the viewport, then
    /// scrolls to the newest move.
    ///
    /// - Parameters:
    ///   - records: Display-ready move records in ply order.
    ///   - selectedPly: Optional ply to render as selected.
    ///   - title: Optional section title. Pass `nil` to hide the title.
    ///   - layout: Move-list layout direction.
    ///   - scrollIndicatorVisibility: Visibility for the active scroll axis.
    ///   - onSelectRecord: Optional callback invoked when a move is selected.
    public init(
        records: [ChessMoveRecord],
        selectedPly: Int? = nil,
        title: String? = "Moves",
        layout: ChessMoveListLayout = .vertical,
        scrollIndicatorVisibility: ScrollIndicatorVisibility = .automatic,
        onSelectRecord: ((ChessMoveRecord) -> Void)? = nil
    ) {
        self.records = records.sorted { $0.ply < $1.ply }
        self.selectedPly = selectedPly
        self.title = title
        self.layout = layout
        self.scrollIndicatorVisibility = scrollIndicatorVisibility
        self.onSelectRecord = onSelectRecord
    }

    /// SwiftUI content for the configured move list.
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.headline)
                    .accessibilityIdentifier("ChessUI.moveList.title")
            }

            if records.isEmpty {
                emptyState
            } else {
                switch layout {
                case .vertical:
                    verticalScrollableMoveRows
                case .horizontal:
                    horizontalScrollableMoveRows
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ChessUI.moveList")
    }

    private var verticalScrollableMoveRows: some View {
        GeometryReader { geometry in
            let viewportHeight = geometry.size.height

            ScrollViewReader { proxy in
                ScrollView {
                    verticalMoveRows
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .defaultScrollAnchor(.top)
                .scrollIndicators(scrollIndicatorVisibility, axes: .vertical)
                .accessibilityIdentifier("ChessUI.moveList.scrollView")
                .task(id: verticalScrollViewIdentity(for: viewportHeight)) {
                    guard shouldAnchorToBottom(in: viewportHeight) else {
                        return
                    }

                    // Let SwiftUI lay out the inserted row before targeting the bottom anchor.
                    try? await Task.sleep(for: .milliseconds(50))
                    withAnimation(.easeOut(duration: 0.16)) {
                        proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var horizontalScrollableMoveRows: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    horizontalMoveGroups
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: viewportWidth, maxHeight: .infinity, alignment: .leading)
                }
                .defaultScrollAnchor(.leading)
                .scrollIndicators(scrollIndicatorVisibility, axes: .horizontal)
                .accessibilityIdentifier("ChessUI.moveList.scrollView")
                .task(id: horizontalScrollViewIdentity(for: viewportWidth)) {
                    guard shouldAnchorToTrailing(in: viewportWidth) else {
                        return
                    }

                    // Let SwiftUI lay out the inserted group before targeting the trailing anchor.
                    try? await Task.sleep(for: .milliseconds(50))
                    withAnimation(.easeOut(duration: 0.16)) {
                        proxy.scrollTo(Self.trailingAnchorID, anchor: .trailing)
                    }
                }
            }
        }
    }

    private var verticalMoveRows: some View {
        VStack(alignment: .leading, spacing: Self.moveRowSpacing) {
            ForEach(Self.rows(from: records)) { row in
                verticalMoveRow(row)
            }

            bottomAnchor
        }
        .padding(.vertical, Self.moveRowsVerticalPadding)
    }

    private var bottomAnchor: some View {
        Color.clear
            .frame(height: 1)
            .id(Self.bottomAnchorID)
            .accessibilityHidden(true)
    }

    private var emptyState: some View {
        Text("No moves yet")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .accessibilityIdentifier("ChessUI.moveList.empty")
    }

    private func verticalMoveRow(_ row: MoveListRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(row.fullMoveNumber).")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)

            moveCell(row.white, placeholder: row.white == nil && row.black != nil ? "..." : "")

            moveCell(row.black, placeholder: "")
        }
    }

    private var horizontalMoveGroups: some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.horizontalGroupSpacing) {
            ForEach(Self.rows(from: records)) { row in
                horizontalMoveGroup(row)
            }

            trailingAnchor
        }
        .padding(.horizontal, Self.horizontalGroupsHorizontalPadding)
    }

    private var trailingAnchor: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .id(Self.trailingAnchorID)
            .accessibilityHidden(true)
    }

    private func horizontalMoveGroup(_ row: MoveListRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.horizontalMoveSpacing) {
            Text("\(row.fullMoveNumber).")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)

            moveCell(row.white, placeholder: row.white == nil && row.black != nil ? "..." : "", expandsHorizontally: false)

            moveCell(row.black, placeholder: "", expandsHorizontally: false)
        }
    }

    @ViewBuilder
    private func moveCell(
        _ record: ChessMoveRecord?,
        placeholder: String,
        expandsHorizontally: Bool = true
    ) -> some View {
        let content = Group {
            if let record {
                if let onSelectRecord {
                    Button {
                        onSelectRecord(record)
                    } label: {
                        moveLabel(record)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("ChessUI.moveList.move.\(record.ply)")
                    .accessibilityLabel(accessibilityLabel(for: record))
                    .accessibilityValue(record.move.description)
                } else {
                    moveLabel(record)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("ChessUI.moveList.move.\(record.ply)")
                        .accessibilityLabel(accessibilityLabel(for: record))
                        .accessibilityValue(record.move.description)
                }
            } else {
                Text(placeholder)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(minHeight: Self.moveRowMinimumHeight, alignment: .leading)
                    .accessibilityHidden(placeholder.isEmpty)
            }
        }

        if expandsHorizontally {
            content.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content.fixedSize(horizontal: true, vertical: false)
        }
    }

    private func moveLabel(_ record: ChessMoveRecord) -> some View {
        Text(record.san)
            .font(.callout.weight(record.ply == selectedPly ? .semibold : .regular))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 7)
            .frame(minHeight: Self.moveRowMinimumHeight, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(record.ply == selectedPly ? Color.accentColor.opacity(0.16) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(record.ply == selectedPly ? Color.accentColor.opacity(0.28) : Color.clear, lineWidth: 1)
            }
    }

    private func accessibilityLabel(for record: ChessMoveRecord) -> String {
        "\(record.fullMoveNumber). \(record.side.accessibilityName) \(record.san)"
    }

    private var latestPly: Int? {
        records.last?.ply
    }

    private func verticalScrollViewIdentity(for viewportHeight: CGFloat) -> MoveListScrollViewIdentity {
        let latestPly = latestPly ?? 0
        let roundedViewportHeight = Int(viewportHeight.rounded(.toNearestOrAwayFromZero))
        return shouldAnchorToBottom(in: viewportHeight)
            ? .verticalOverflowing(latestPly, roundedViewportHeight)
            : .verticalFitting(latestPly, roundedViewportHeight)
    }

    private func horizontalScrollViewIdentity(for viewportWidth: CGFloat) -> MoveListScrollViewIdentity {
        let latestPly = latestPly ?? 0
        let roundedViewportWidth = Int(viewportWidth.rounded(.toNearestOrAwayFromZero))
        return shouldAnchorToTrailing(in: viewportWidth)
            ? .horizontalOverflowing(latestPly, roundedViewportWidth)
            : .horizontalFitting(latestPly, roundedViewportWidth)
    }

    private func shouldAnchorToBottom(in viewportHeight: CGFloat) -> Bool {
        viewportHeight > 0 && estimatedMoveRowsHeight > viewportHeight + 1
    }

    private func shouldAnchorToTrailing(in viewportWidth: CGFloat) -> Bool {
        viewportWidth > 0 && estimatedMoveGroupsWidth > viewportWidth + 1
    }

    private var estimatedMoveRowsHeight: CGFloat {
        let rowCount = CGFloat(Self.rows(from: records).count)
        guard rowCount > 0 else {
            return 0
        }

        return rowCount * Self.moveRowMinimumHeight
            + max(0, rowCount - 1) * Self.moveRowSpacing
            + Self.moveRowsVerticalPadding * 2
    }

    private var estimatedMoveGroupsWidth: CGFloat {
        let rows = Self.rows(from: records)
        guard !rows.isEmpty else {
            return 0
        }

        let groupWidths = rows.reduce(CGFloat.zero) { partialWidth, row in
            partialWidth + Self.estimatedWidth(for: row)
        }
        return groupWidths
            + CGFloat(rows.count - 1) * Self.horizontalGroupSpacing
            + Self.horizontalGroupsHorizontalPadding * 2
    }

    private static func estimatedWidth(for row: MoveListRow) -> CGFloat {
        estimatedMoveNumberWidth
            + estimatedWidth(for: row.white)
            + estimatedWidth(for: row.black)
            + horizontalMoveSpacing * 2
    }

    private static func estimatedWidth(for record: ChessMoveRecord?) -> CGFloat {
        guard let record else {
            return estimatedMoveHorizontalPadding
        }

        return max(22, CGFloat(record.san.count) * estimatedCharacterWidth + estimatedMoveHorizontalPadding)
    }

    private static func rows(from records: [ChessMoveRecord]) -> [MoveListRow] {
        var rows: [MoveListRow] = []

        for record in records {
            if let index = rows.firstIndex(where: { $0.fullMoveNumber == record.fullMoveNumber }) {
                rows[index].update(with: record)
            } else {
                var row = MoveListRow(fullMoveNumber: record.fullMoveNumber)
                row.update(with: record)
                rows.append(row)
            }
        }

        return rows.sorted { $0.fullMoveNumber < $1.fullMoveNumber }
    }
}

private enum MoveListScrollViewIdentity: Hashable {
    case verticalFitting(Int, Int)
    case verticalOverflowing(Int, Int)
    case horizontalFitting(Int, Int)
    case horizontalOverflowing(Int, Int)
}

private struct MoveListRow: Identifiable {
    let fullMoveNumber: Int
    var white: ChessMoveRecord?
    var black: ChessMoveRecord?

    var id: Int { fullMoveNumber }

    mutating func update(with record: ChessMoveRecord) {
        switch record.side {
        case .white:
            white = record
        case .black:
            black = record
        }
    }
}

private extension PieceColor {
    var accessibilityName: String {
        switch self {
        case .white:
            "White"
        case .black:
            "Black"
        }
    }
}
