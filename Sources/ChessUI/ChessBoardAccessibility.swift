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

struct ChessBoardSquareAccessibilityState: Equatable, Sendable {
    var label: String
    var hint: String
    var isActivatable: Bool
    var isSelected: Bool
    var isLegalDestination: Bool
    var isCaptureDestination: Bool
}

extension ChessBoardModel {
    func accessibilityState(for square: BoardSquare) -> ChessBoardSquareAccessibilityState {
        let squarePiece = piece(at: square)
        let selectedPiece = selectedSquare.flatMap { piece(at: $0) }
        let isSelected = selectedSquare == square
        let legalMove = selectedSquare.map { legalMoves(from: $0, to: square).isEmpty == false } ?? false
        let isCapture = legalMove && squarePiece != nil && squarePiece?.color != selectedPiece?.color
        let isWaitingForAnimation = movingPiece != nil
        let canSelectPiece = squarePiece.map { interactionMode.canInteract(with: $0, turn: turn) } ?? false
        let wrongSidePiece = selectedSquare == nil
            && squarePiece != nil
            && interactionMode != .readOnly
            && canSelectPiece == false
        let hasSelection = selectedSquare != nil
        let isActivatable = isWaitingForAnimation == false
            && interactionMode != .readOnly
            && (hasSelection || canSelectPiece)

        return ChessBoardSquareAccessibilityState(
            label: accessibilityLabel(
                for: square,
                piece: squarePiece,
                isSelected: isSelected,
                isLegalDestination: legalMove,
                isCaptureDestination: isCapture,
                isWrongSidePiece: wrongSidePiece
            ),
            hint: accessibilityHint(
                for: square,
                piece: squarePiece,
                isSelected: isSelected,
                isLegalDestination: legalMove,
                isCaptureDestination: isCapture,
                isWaitingForAnimation: isWaitingForAnimation,
                canSelectPiece: canSelectPiece,
                hasSelection: hasSelection
            ),
            isActivatable: isActivatable,
            isSelected: isSelected,
            isLegalDestination: legalMove,
            isCaptureDestination: isCapture
        )
    }

    @discardableResult
    func activate(square: BoardSquare) -> String? {
        if movingPiece != nil || interactionMode == .readOnly {
            return nil
        }

        if let piece = piece(at: square),
           !interactionMode.canInteract(with: piece, turn: turn),
           selectedSquare == nil
        {
            return nil
        }

        if selectedSquare == square {
            deselect()
            return "Selection cleared."
        } else if piece(at: square) != nil && selectedSquare == nil {
            selectedSquare = square
            updateLegalMoveHighlights(for: square)
            return selectionAnnouncement(for: square)
        } else if let selectedSquare {
            return reportMoveAttempt(from: selectedSquare, to: square)
        }

        return nil
    }

    func selectionAnnouncement(for square: BoardSquare) -> String? {
        guard let piece = piece(at: square) else {
            return nil
        }

        let coordinate = square.coordinate
        let destinations = legalMoves(from: square)
            .map(\.to.coordinate)
            .uniqued()
            .sorted()

        if destinations.isEmpty {
            return "\(piece.accessibilityName) selected on \(coordinate). No legal moves."
        }

        return "\(piece.accessibilityName) selected on \(coordinate). Legal moves: \(destinations.joined(separator: ", "))."
    }

    private func reportMoveAttempt(from selectedSquare: BoardSquare, to targetSquare: BoardSquare) -> String? {
        let sourceSquare = selectedSquare.coordinate
        let targetSquare = targetSquare.coordinate
        let coordinateMove = "\(sourceSquare)\(targetSquare)"

        deselect()
        clearLegalMoveHighlights()

        guard let move = try? Move(string: coordinateMove) else {
            return nil
        }

        let isLegal = game.legalMoves.contains(move)

        guard let selectedPiece = piece(at: selectedSquare) else {
            return nil
        }

        let requiresPromotionChoice = requiresPromotionChoice(piece: selectedPiece, move: move)

        if !requiresPromotionChoice {
            return reportMoveAndDescribe(
                move,
                isLegal: isLegal,
                sourceSquare: sourceSquare,
                targetSquare: targetSquare,
                coordinateMove: coordinateMove
            )
        } else if promotionKinds.contains(where: { promotion in
            game.legalMoves.contains(Move(from: move.from, to: move.to, promotion: promotion))
        }) {
            presentPromotionPicker(
                piece: selectedPiece,
                sourceSquare: sourceSquare,
                targetSquare: targetSquare,
                baseMove: move
            )
            return "Choose promotion piece."
        } else {
            return reportMoveAndDescribe(
                move,
                isLegal: isLegal,
                sourceSquare: sourceSquare,
                targetSquare: targetSquare,
                coordinateMove: coordinateMove
            )
        }
    }

    private func reportMoveAndDescribe(
        _ move: Move,
        isLegal: Bool,
        sourceSquare: String,
        targetSquare: String,
        coordinateMove: String
    ) -> String {
        let shouldReport = interactionMode.shouldReportMove(isLegal: isLegal)

        reportMove(
            move,
            isLegal: isLegal,
            sourceSquare: sourceSquare,
            targetSquare: targetSquare,
            coordinateMove: coordinateMove
        )

        if isLegal {
            return "Move \(sourceSquare) to \(targetSquare) requested."
        }

        if shouldReport {
            return "Illegal move \(sourceSquare) to \(targetSquare) requested."
        }

        return "Selection cleared. Not a legal move."
    }

    private func accessibilityLabel(
        for square: BoardSquare,
        piece: Piece?,
        isSelected: Bool,
        isLegalDestination: Bool,
        isCaptureDestination: Bool,
        isWrongSidePiece: Bool
    ) -> String {
        var parts = [piece?.accessibilityName ?? "Empty", square.coordinate]

        if isSelected {
            parts.append("selected")
        } else if isCaptureDestination {
            parts.append("legal capture")
        } else if isLegalDestination {
            parts.append("legal destination")
        } else if isWrongSidePiece {
            parts.append("not side to move")
        }

        return parts.joined(separator: ", ")
    }

    private func accessibilityHint(
        for square: BoardSquare,
        piece: Piece?,
        isSelected: Bool,
        isLegalDestination: Bool,
        isCaptureDestination: Bool,
        isWaitingForAnimation: Bool,
        canSelectPiece: Bool,
        hasSelection: Bool
    ) -> String {
        if isWaitingForAnimation {
            return "Wait for the current move animation to finish."
        }

        if interactionMode == .readOnly {
            return "Read-only board."
        }

        if isSelected {
            return "Activate to clear selection."
        }

        if hasSelection {
            if isCaptureDestination {
                return "Activate to capture on this square."
            }

            if isLegalDestination {
                return "Activate to move here."
            }

            if interactionMode.shouldReportMove(isLegal: false) {
                return "Activate to report this move attempt."
            }

            return "Not a legal destination. Activate to clear selection."
        }

        if piece != nil && canSelectPiece {
            return "Activate to select this piece."
        }

        if piece != nil {
            return "Only \(turn.accessibilityName) can move."
        }

        return "Empty square."
    }

    private func piece(at square: BoardSquare) -> Piece? {
        game.position.board[square.index]
    }

    private func legalMoves(from source: BoardSquare, to target: BoardSquare? = nil) -> [Move] {
        game.legalMoves.filter { move in
            move.from.rank == source.row
                && move.from.file == source.column
                && (target == nil || (move.to.rank == target?.row && move.to.file == target?.column))
        }
    }
}

private let promotionKinds: [PieceKind] = [.queen, .rook, .bishop, .knight]

extension BoardSquare {
    var index: Int {
        row + column * 8
    }

    var coordinate: String {
        let file = Character(UnicodeScalar(column + 97)!)
        return "\(file)\(row + 1)"
    }
}

private extension Piece {
    var accessibilityName: String {
        "\(color.accessibilityName) \(kind.accessibilityName)"
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

private extension PieceKind {
    var accessibilityName: String {
        switch self {
        case .king:
            "king"
        case .queen:
            "queen"
        case .rook:
            "rook"
        case .bishop:
            "bishop"
        case .knight:
            "knight"
        case .pawn:
            "pawn"
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()

        return filter { seen.insert($0).inserted }
    }
}
