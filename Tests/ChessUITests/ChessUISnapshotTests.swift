//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

#if os(macOS)
import AppKit
import CoreGraphics
import ImageIO
import SwiftUI
import Testing

import ChessCore
import ChessUI

@MainActor
@Test func initialWhitePerspectiveSnapshot() throws {
    try assertBoardSnapshot(named: "initial-white") {
        ChessBoardView(model: ChessBoardModel(fen: initialFEN))
    }
}

@MainActor
@Test func initialBlackPerspectiveSnapshot() throws {
    try assertBoardSnapshot(named: "initial-black") {
        ChessBoardView(model: ChessBoardModel(fen: initialFEN, perspective: .black))
    }
}

@MainActor
@Test func selectedPieceSnapshot() throws {
    let model = ChessBoardModel(fen: initialFEN)
    model.selectedSquare = BoardSquare(row: 1, column: 4)
    model.updateLegalMoveHighlights(for: BoardSquare(row: 1, column: 4))

    try assertBoardSnapshot(named: "selected-piece") {
        ChessBoardView(model: model)
    }
}

@MainActor
@Test func lastMoveHighlightSnapshot() throws {
    let model = ChessBoardModel(fen: initialFEN)
    let move = try! Move(string: "e2e4")
    model.game.apply(move: move)
    model.setFEN(FENSerializer().fen(from: model.game.position), animatedMove: move)
    model.movingPiece = nil

    try assertBoardSnapshot(named: "last-move-highlight") {
        ChessBoardView(model: model)
    }
}

@MainActor
@Test func promotionPickerSnapshot() throws {
    let model = ChessBoardModel(fen: "7k/4P3/8/8/8/8/8/4K3 w - - 0 1")
    model.presentPromotionPicker(
        piece: Piece(kind: .pawn, color: .white),
        sourceSquare: "e7",
        targetSquare: "e8",
        baseMove: try! Move(string: "e7e8")
    )

    try assertBoardSnapshot(named: "promotion-picker") {
        ChessBoardView(model: model)
    }
}

@MainActor
@Test func builtInPieceSetSnapshots() throws {
    for pieceSet in ChessPieceSet.availableSets {
        try assertBoardSnapshot(named: "piece-set-\(pieceSet.rawValue)") {
            ChessBoardView(model: ChessBoardModel(fen: initialFEN, pieceSet: pieceSet))
        }
    }
}

@MainActor
@Test func builtInBoardThemeSnapshots() throws {
    for boardTheme in ChessBoardTheme.availableThemes {
        try assertBoardSnapshot(named: "board-theme-\(boardTheme.rawValue)") {
            ChessBoardView(model: ChessBoardModel(fen: initialFEN, boardTheme: boardTheme, pieceSet: .artDecoMonochrome))
        }
    }
}

@MainActor
@Test func moveListViewRendersEmptyState() throws {
    try assertViewSnapshot(
        named: "move-list-empty",
        size: CGSize(width: 264, height: 144)
    ) {
        ChessMoveListView(records: [])
            .frame(width: 240, height: 120)
            .padding(12)
            .background(Color.white)
    }
}

@MainActor
@Test func moveListViewRendersMoveRows() throws {
    let records = try sampleMoveRecords()

    try assertViewSnapshot(
        named: "move-list-rows",
        size: CGSize(width: 264, height: 184)
    ) {
        ChessMoveListView(
            records: records,
            selectedPly: 2,
            title: "Moves"
        ) { _ in }
        .frame(width: 240, height: 160)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersLongHistoryInFixedViewport() throws {
    try assertViewSnapshot(
        named: "move-list-long-history",
        size: CGSize(width: 264, height: 144)
    ) {
        ChessMoveListView(
            records: sampleLongMoveRecords(),
            selectedPly: 40,
            title: "Moves"
        ) { _ in }
        .frame(width: 240, height: 120)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersLongHistoryWithHiddenScrollIndicators() throws {
    try assertViewSnapshot(
        named: "move-list-hidden-scroll-indicators",
        size: CGSize(width: 264, height: 144)
    ) {
        ChessMoveListView(
            records: sampleLongMoveRecords(),
            selectedPly: 40,
            title: "Moves",
            scrollIndicatorVisibility: .hidden
        ) { _ in }
        .frame(width: 240, height: 120)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersHorizontalMoveRows() throws {
    let records = try sampleMoveRecords()

    try assertViewSnapshot(
        named: "move-list-horizontal-rows",
        size: CGSize(width: 284, height: 80)
    ) {
        ChessMoveListView(
            records: records,
            selectedPly: 2,
            title: "Moves",
            layout: .horizontal
        ) { _ in }
        .frame(width: 260, height: 56)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersHorizontalLongHistoryInFixedViewport() throws {
    try assertViewSnapshot(
        named: "move-list-horizontal-long-history",
        size: CGSize(width: 284, height: 80)
    ) {
        ChessMoveListView(
            records: sampleLongMoveRecords(),
            selectedPly: 40,
            title: "Moves",
            layout: .horizontal
        ) { _ in }
        .frame(width: 260, height: 56)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersHorizontalWithHiddenScrollIndicators() throws {
    try assertViewSnapshot(
        named: "move-list-horizontal-hidden-scroll-indicators",
        size: CGSize(width: 284, height: 80)
    ) {
        ChessMoveListView(
            records: sampleLongMoveRecords(),
            selectedPly: 40,
            title: "Moves",
            layout: .horizontal,
            scrollIndicatorVisibility: .hidden
        ) { _ in }
        .frame(width: 260, height: 56)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersNarrowSelectedRows() throws {
    try assertViewSnapshot(
        named: "move-list-narrow-selected-rows",
        size: CGSize(width: 172, height: 184)
    ) {
        ChessMoveListView(
            records: sampleNotationHeavyMoveRecords(),
            selectedPly: 5,
            title: "Moves"
        ) { _ in }
        .frame(width: 148, height: 160)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func moveListViewRendersHorizontalNarrowRows() throws {
    try assertViewSnapshot(
        named: "move-list-horizontal-narrow-rows",
        size: CGSize(width: 184, height: 80)
    ) {
        ChessMoveListView(
            records: sampleNotationHeavyMoveRecords(),
            selectedPly: 5,
            title: "Moves",
            layout: .horizontal
        ) { _ in }
        .frame(width: 160, height: 56)
        .padding(12)
        .background(Color.white)
        .tint(.blue)
    }
}

@MainActor
@Test func evaluationBarRendersVerticalCentipawnSnapshot() throws {
    try assertViewSnapshot(
        named: "evaluation-bar-vertical-centipawn",
        size: CGSize(width: 60, height: 184)
    ) {
        ChessEvaluationBar(
            evaluation: .centipawns(250),
            orientation: .vertical,
            whiteSide: .bottom,
            maximumCentipawns: 800
        )
        .frame(width: 36, height: 160)
        .padding(12)
        .background(Color.white)
    }
}

@MainActor
@Test func evaluationBarRendersMateSnapshots() throws {
    try assertViewSnapshot(
        named: "evaluation-bar-mate-vertical",
        size: CGSize(width: 108, height: 184)
    ) {
        HStack(spacing: 12) {
            ChessEvaluationBar(evaluation: .mate(moves: 3, side: .white))
                .frame(width: 36, height: 160)

            ChessEvaluationBar(evaluation: .mate(moves: 2, side: .black))
                .frame(width: 36, height: 160)
        }
        .padding(12)
        .background(Color.white)
    }
}

@MainActor
@Test func evaluationBarRendersUnavailableSnapshot() throws {
    try assertViewSnapshot(
        named: "evaluation-bar-unavailable",
        size: CGSize(width: 60, height: 184)
    ) {
        ChessEvaluationBar(evaluation: .unavailable)
            .frame(width: 36, height: 160)
            .padding(12)
            .background(Color.white)
    }
}

@MainActor
@Test func evaluationBarRendersHorizontalSnapshot() throws {
    try assertViewSnapshot(
        named: "evaluation-bar-horizontal",
        size: CGSize(width: 204, height: 60)
    ) {
        ChessEvaluationBar(
            evaluation: .centipawns(-350),
            orientation: .horizontal,
            whiteSide: .leading,
            maximumCentipawns: 800
        )
        .frame(width: 180, height: 36)
        .padding(12)
        .background(Color.white)
    }
}

@MainActor
@Test func evaluationBarRendersMinimumSizeSnapshot() throws {
    try assertViewSnapshot(
        named: "evaluation-bar-minimum-size",
        size: CGSize(width: 46, height: 144)
    ) {
        ChessEvaluationBar(
            evaluation: .centipawns(85),
            orientation: .vertical,
            whiteSide: .bottom,
            maximumCentipawns: 800
        )
        .frame(width: 22, height: 120)
        .padding(12)
        .background(Color.white)
    }
}

@MainActor
private func assertBoardSnapshot<Content: View>(
    named name: String,
    @ViewBuilder content: () -> Content
) throws {
    try assertViewSnapshot(named: name, size: CGSize(width: 320, height: 320)) {
        content()
            .frame(width: 320, height: 320)
            .background(Color.white)
    }
}

@MainActor
private func assertViewSnapshot<Content: View>(
    named name: String,
    size: CGSize,
    @ViewBuilder content: () -> Content
) throws {
    let actualPNG = try renderPNG(content(), size: size)
    if ProcessInfo.processInfo.environment["RECORD_CHESSUI_SNAPSHOTS"] == "1" {
        let outputURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SnapshotReferences")
            .appendingPathComponent("\(name).png")
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try actualPNG.write(to: outputURL)
        return
    }

    let referenceURL = Bundle.module.url(forResource: name, withExtension: "png")
        ?? Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "SnapshotReferences"
        )

    guard let referenceURL else {
        Issue.record("Missing ChessUI snapshot reference: \(name).png")
        return
    }

    let expectedPNG = try Data(contentsOf: referenceURL)
    try assertImagesMatch(expectedPNG, actualPNG, snapshotName: name)
}

@MainActor
private func renderPNG<Content: View>(_ view: Content, size: CGSize) throws -> Data {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(size)

    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw SnapshotError.renderingFailed
    }

    return png
}

private func assertImagesMatch(_ expectedPNG: Data, _ actualPNG: Data, snapshotName: String) throws {
    let expected = try rgbaBitmap(from: expectedPNG)
    let actual = try rgbaBitmap(from: actualPNG)

    #expect(expected.width == actual.width, "\(snapshotName) width")
    #expect(expected.height == actual.height, "\(snapshotName) height")

    guard expected.width == actual.width, expected.height == actual.height else {
        return
    }

    var differingPixels = 0
    let pixelCount = expected.width * expected.height

    for index in stride(from: 0, to: expected.pixels.count, by: 4) {
        let redDelta = abs(Int(expected.pixels[index]) - Int(actual.pixels[index]))
        let greenDelta = abs(Int(expected.pixels[index + 1]) - Int(actual.pixels[index + 1]))
        let blueDelta = abs(Int(expected.pixels[index + 2]) - Int(actual.pixels[index + 2]))
        let alphaDelta = abs(Int(expected.pixels[index + 3]) - Int(actual.pixels[index + 3]))

        if max(redDelta, greenDelta, blueDelta, alphaDelta) > 3 {
            differingPixels += 1
        }
    }

    let mismatchRatio = Double(differingPixels) / Double(pixelCount)
    #expect(mismatchRatio <= 0.002, "\(snapshotName) pixel mismatch ratio: \(mismatchRatio)")
}

private func sampleMoveRecords() throws -> [ChessMoveRecord] {
    try ChessMoveRecordBuilder().records(
        initialPosition: FENSerializer().position(from: initialFEN),
        moves: [
            Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e4")),
            Move(from: Square(coordinate: "e7"), to: Square(coordinate: "e5")),
            Move(from: Square(coordinate: "g1"), to: Square(coordinate: "f3")),
        ]
    )
}

private func sampleNotationHeavyMoveRecords() -> [ChessMoveRecord] {
    [
        ChessMoveRecord(
            ply: 1,
            fullMoveNumber: 1,
            side: .white,
            move: Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e4")),
            san: "e4"
        ),
        ChessMoveRecord(
            ply: 2,
            fullMoveNumber: 1,
            side: .black,
            move: Move(from: Square(coordinate: "e7"), to: Square(coordinate: "e5")),
            san: "e5"
        ),
        ChessMoveRecord(
            ply: 3,
            fullMoveNumber: 2,
            side: .white,
            move: Move(from: Square(coordinate: "g1"), to: Square(coordinate: "f3")),
            san: "Nf3"
        ),
        ChessMoveRecord(
            ply: 4,
            fullMoveNumber: 2,
            side: .black,
            move: Move(from: Square(coordinate: "b8"), to: Square(coordinate: "c6")),
            san: "Nc6"
        ),
        ChessMoveRecord(
            ply: 5,
            fullMoveNumber: 3,
            side: .white,
            move: Move(from: Square(coordinate: "e7"), to: Square(coordinate: "e8"), promotion: .queen),
            san: "exd8=Q+"
        ),
        ChessMoveRecord(
            ply: 6,
            fullMoveNumber: 3,
            side: .black,
            move: Move(from: Square(coordinate: "e8"), to: Square(coordinate: "g8")),
            san: "O-O+"
        ),
    ]
}

private func sampleLongMoveRecords() -> [ChessMoveRecord] {
    (1...40).map { ply in
        ChessMoveRecord(
            ply: ply,
            fullMoveNumber: (ply + 1) / 2,
            side: ply.isMultiple(of: 2) ? .black : .white,
            move: Move(
                from: Square(coordinate: ply.isMultiple(of: 2) ? "e7" : "e2"),
                to: Square(coordinate: ply.isMultiple(of: 2) ? "e5" : "e4")
            ),
            san: ply.isMultiple(of: 2) ? "e5" : "e4"
        )
    }
}

private func rgbaBitmap(from png: Data) throws -> (width: Int, height: Int, pixels: [UInt8]) {
    guard let source = CGImageSourceCreateWithData(png as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw SnapshotError.imageDecodingFailed
    }

    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)

    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw SnapshotError.imageDecodingFailed
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (width, height, pixels)
}

private enum SnapshotError: Error {
    case renderingFailed
    case imageDecodingFailed
}
#endif
