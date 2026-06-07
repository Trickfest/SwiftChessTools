//
//  ChessUISnapshotTests.swift
//  ChessUITests
//
//  Copyright © 2026 Päike Mikrosüsteemid OÜ. All rights reserved.
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
private func assertBoardSnapshot<Content: View>(
    named name: String,
    @ViewBuilder content: () -> Content
) throws {
    let actualPNG = try renderPNG(
        content()
            .frame(width: 320, height: 320)
            .background(Color.white),
        size: CGSize(width: 320, height: 320)
    )

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
