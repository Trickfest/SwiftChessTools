//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import CoreGraphics
import ChessUI
import ImageIO
import XCTest

final class ChessWorkbenchUITests: XCTestCase {
    private static let startingFEN = "5k2/1P2bn2/8/8/8/3Q4/3K4/8 w - - 0 1"
    private static let queenD7FEN = "5k2/1P1Qbn2/8/8/8/8/3K4/8 b - - 1 1"
    private static let fiftyMoveClaimFEN = "4k3/8/8/8/8/8/Q7/4K3 w - - 100 1"
    private static let knightCycleFEN = "6nk/8/8/8/8/8/8/K5N1 w - - 0 1"
    private static let knightCycleFinalFEN = "6nk/8/8/8/8/8/8/K5N1 w - - 20 11"

    private var pieceSetNames: [String] {
        ChessPieceSet.availableSets.map(\.displayName)
    }

    private var boardThemeNames: [String] {
        ChessBoardTheme.availableThemes.map(\.displayName)
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        openWindowIfNeeded()
        waitForFEN(Self.startingFEN, timeout: 8)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testBoardRendersExpectedStartingPosition() {
        XCTAssertTrue(square("b7").label.contains("White pawn, b7"))
        XCTAssertTrue(square("d3").label.contains("White queen, d3"))
        XCTAssertTrue(square("d2").label.contains("White king, d2"))
        XCTAssertTrue(square("e7").label.contains("Black bishop, e7"))
        XCTAssertTrue(square("f7").label.contains("Black knight, f7"))
        XCTAssertTrue(square("f8").label.contains("Black king, f8"))
    }

    func testPieceSetPickerSelectsEveryBuiltInSet() {
        let picker = element("Workbench.pieceSetPicker")

        assertExists(picker)
        XCTAssertEqual(picker.value as? String, ChessPieceSet.artDecoMonochrome.displayName)

        for pieceSetName in pieceSetNames {
            picker.click()
            let menuItem = app.menuItems[pieceSetName]
            assertExists(menuItem, message: "Missing piece set menu item \(pieceSetName)")
            menuItem.click()
            waitForValue(pieceSetName, in: picker)
        }
    }

    func testBoardThemePickerSelectsEveryBuiltInTheme() {
        let picker = element("Workbench.boardThemePicker")

        assertExists(picker)
        XCTAssertEqual(picker.value as? String, ChessBoardTheme.artDecoMonochrome.displayName)

        for boardThemeName in boardThemeNames {
            picker.click()
            let menuItem = app.menuItems[boardThemeName]
            assertExists(menuItem, message: "Missing board theme menu item \(boardThemeName)")
            menuItem.click()
            waitForValue(boardThemeName, in: picker)
            assertBoardScreenshotIsNotBlank(square("b1"), themeName: boardThemeName)
        }

        tapSquare("d3")
        assertExists(element("ChessUI.legalMove.d7"))
    }

    func testDisplayPickersHaveAlignedFrames() {
        let piecePicker = element("Workbench.pieceSetPicker")
        let boardPicker = element("Workbench.boardThemePicker")
        let moveListPicker = element("Workbench.moveListLayoutPicker")
        let scrollBarsToggle = element("Workbench.moveListScrollBarsToggle")
        let coordinateLabelsToggle = element("Workbench.coordinateLabelsToggle")

        assertExists(piecePicker)
        assertExists(boardPicker)
        assertExists(moveListPicker)
        assertExists(scrollBarsToggle)
        assertExists(coordinateLabelsToggle)
        XCTAssertEqual(piecePicker.frame.minX, boardPicker.frame.minX, accuracy: 1)
        XCTAssertEqual(piecePicker.frame.width, boardPicker.frame.width, accuracy: 1)
        XCTAssertEqual(piecePicker.frame.height, boardPicker.frame.height, accuracy: 1)
        XCTAssertEqual(piecePicker.frame.minX, moveListPicker.frame.minX, accuracy: 1)
        XCTAssertEqual(piecePicker.frame.width, moveListPicker.frame.width, accuracy: 1)
        XCTAssertEqual(piecePicker.frame.height, moveListPicker.frame.height, accuracy: 1)
    }

    func testCoordinateLabelsTogglePreservesBoardInteraction() {
        let toggle = element("Workbench.coordinateLabelsToggle")
        let state = element("Workbench.coordinateLabelsState")
        assertExists(toggle)
        assertExists(state)

        waitForText("Coordinate labels Shown", in: state)
        toggle.click()
        waitForText("Coordinate labels Hidden", in: state)

        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)
    }

    func testEvaluationBarControlsDemoSamplesAndPlacement() {
        let bar = element("Workbench.evaluationBar")
        let samplePicker = element("Workbench.evaluationSamplePicker")
        let placementPicker = element("Workbench.evaluationPlacementPicker")
        let whiteSidePicker = element("Workbench.evaluationWhiteSidePicker")
        let status = element("Workbench.evaluationStatus")

        assertExists(bar)
        assertExists(samplePicker)
        assertExists(placementPicker)
        assertExists(whiteSidePicker)
        assertExists(status)
        assertExists(element("Workbench.evaluationLabelToggle"))
        assertExists(element("Workbench.evaluationScaleSlider"))

        waitForFrameOrientation(bar, isHorizontal: false)
        waitForText("White advantage 0.9 pawns", in: status)
        assertEvaluationBarScreenshotHasLightAndDarkSegments(bar)

        samplePicker.click()
        menuActionItem("Black mate in 2").click()
        waitForValue("Black mate in 2", in: samplePicker)
        waitForText("Black mate in 2", in: status)

        placementPicker.click()
        menuActionItem("Top").click()
        waitForValue("Top", in: placementPicker)
        waitForValue("White at leading", in: whiteSidePicker)
        waitForFrameOrientation(bar, isHorizontal: true)
    }

    func testGameStatusViewTracksTurnsAndDrawClaims() {
        let status = element("ChessUI.gameStatus.text")

        assertExists(element("Workbench.gameStatus"))
        waitForText("White to move", in: status)

        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)
        waitForText("Black to move", in: status)

        setFEN(Self.fiftyMoveClaimFEN)
        waitForText("White to move. Draw claim available: fifty-move rule", in: status)

        let claimButton = app.buttons["ChessUI.gameStatus.claim.fiftyMoveRule"]
        assertExists(claimButton)
        claimButton.click()

        waitForText("Draw by fifty-move rule", in: status)
    }

    func testSourceSquareClickSelectsPieceAndShowsLegalDestinations() {
        tapSquare("d3")

        assertExists(element("ChessUI.legalMove.d7"))
        assertExists(element("ChessUI.legalMove.h7"))
    }

    func testDestinationSquareClickWorksAcrossFullSquare() {
        let offsets = [
            CGVector(dx: 0.08, dy: 0.08),
            CGVector(dx: 0.92, dy: 0.08),
            CGVector(dx: 0.08, dy: 0.92),
            CGVector(dx: 0.92, dy: 0.92),
        ]

        for offset in offsets {
            moveQueenToD7(targetOffset: offset)
            waitForFEN(Self.queenD7FEN)
            XCTAssertTrue(square("d7").label.contains("White queen, d7"))
            resetPosition()
        }
    }

    func testLegalMoveUpdatesFENField() {
        moveQueenToD7()

        waitForFEN(Self.queenD7FEN)
        XCTAssertTrue(square("d7").label.contains("White queen, d7"))
        assertExists(element("ChessUI.lastMove.d3"))
        assertExists(element("ChessUI.lastMove.d7"))
    }

    func testMoveListUpdatesAfterLegalMoveAndClearsOnReset() {
        assertExists(element("ChessUI.moveList.empty"))

        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)

        let moveList = element("ChessUI.moveList")
        let firstMove = element("ChessUI.moveList.move.1")
        assertExists(moveList)
        assertExists(firstMove)
        XCTAssertTrue(firstMove.label.contains("1. White Qd7"))
        assertElementIsNearTop(firstMove, of: moveList)

        resetPosition()

        assertExists(element("ChessUI.moveList.empty"))
    }

    func testMoveListKeepsNewestMoveVisibleForLongHistory() {
        setFEN(Self.knightCycleFEN)

        playKnightCycleHistory()

        waitForFEN(Self.knightCycleFinalFEN, timeout: 4)

        let moveList = element("ChessUI.moveList")
        let newestMove = element("ChessUI.moveList.move.20")
        assertExists(moveList)
        waitForHittable(newestMove, timeout: 3, message: "Newest move should be visible after long history")
        XCTAssertGreaterThanOrEqual(newestMove.frame.minY, moveList.frame.minY - 1)
        XCTAssertLessThanOrEqual(newestMove.frame.maxY, moveList.frame.maxY + 1)
    }

    func testHorizontalMoveListUpdatesAfterLegalMoveAndClearsOnReset() {
        selectMoveListLayout("Horizontal")
        assertExists(element("ChessUI.moveList.empty"))
        assertHorizontalMoveListStripAlignsWithBoardCard()

        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)

        let moveList = element("ChessUI.moveList")
        let firstMove = element("ChessUI.moveList.move.1")
        assertExists(moveList)
        assertExists(firstMove)
        XCTAssertTrue(firstMove.label.contains("1. White Qd7"))
        assertElementIsNearLeading(firstMove, of: moveList)

        resetPosition()

        assertExists(element("ChessUI.moveList.empty"))
    }

    func testMoveListScrollBarsTogglePreservesMoveListBehavior() {
        toggleMoveListScrollBars()

        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)
        assertExists(element("ChessUI.moveList"))
        assertExists(element("ChessUI.moveList.move.1"))

        resetPosition()
        toggleMoveListScrollBars()
        selectMoveListLayout("Horizontal")

        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)
        assertExists(element("ChessUI.moveList"))
        assertExists(element("ChessUI.moveList.move.1"))
        assertHorizontalMoveListStripAlignsWithBoardCard()
    }

    func testHorizontalMoveListKeepsNewestMoveVisibleForLongHistory() {
        selectMoveListLayout("Horizontal")
        setFEN(Self.knightCycleFEN)

        playKnightCycleHistory()

        waitForFEN(Self.knightCycleFinalFEN, timeout: 4)

        let moveList = element("ChessUI.moveList")
        let newestMove = element("ChessUI.moveList.move.20")
        assertExists(moveList)
        waitForHittable(newestMove, timeout: 3, message: "Newest horizontal move should be visible after long history")
        assertElementIsHorizontallyInside(newestMove, of: moveList)
    }

    func testInvalidMoveDoesNotUpdateFEN() {
        tapSquare("d3")
        tapSquare("e5")

        waitForFEN(Self.startingFEN)
        XCTAssertTrue(square("d3").label.contains("White queen, d3"))
        XCTAssertTrue(square("e5").label.contains("Empty, e5"))
    }

    func testShowD3MarkerDisplaysMarker() {
        app.buttons["Workbench.showD3Marker"].tap()

        assertExists(element("ChessUI.hint.d3"))
    }

    func testArrowControlsRenderAndClearBoardArrows() {
        app.buttons["Workbench.showBestArrow"].tap()
        assertExists(element("ChessUI.arrow.d3.d7"))

        app.buttons["Workbench.showTopThreeArrows"].tap()
        assertExists(element("ChessUI.arrow.d3.d7"))
        assertExists(element("ChessUI.arrow.d3.h7"))
        assertExists(element("ChessUI.arrow.b7.b8"))

        app.buttons["Workbench.clearArrows"].tap()
        waitForNonExistence(element("ChessUI.arrow.d3.d7"))
        waitForNonExistence(element("ChessUI.arrow.d3.h7"))
        waitForNonExistence(element("ChessUI.arrow.b7.b8"))
    }

    func testShowPromotionDisplaysPromotionChoices() {
        app.buttons["Workbench.showPromotion"].tap()

        assertExists(app.buttons["ChessUI.promotion.queen"])
        XCTAssertTrue(app.buttons["ChessUI.promotion.rook"].exists)
        XCTAssertTrue(app.buttons["ChessUI.promotion.bishop"].exists)
        XCTAssertTrue(app.buttons["ChessUI.promotion.knight"].exists)
    }

    func testCopyFENChangesLabelWithoutMovingSurroundingControls() {
        let copyButton = app.buttons["Workbench.copyFEN"]
        let resetButton = app.buttons["Workbench.resetPosition"]
        assertExists(copyButton)
        assertExists(resetButton)
        let resetFrame = resetButton.frame

        copyButton.tap()

        let copiedPredicate = NSPredicate(format: "label == %@", "Copied FEN")
        expectation(for: copiedPredicate, evaluatedWith: copyButton)
        waitForExpectations(timeout: 2)
        assertFrame(resetButton.frame, isCloseTo: resetFrame)
    }

    func testResetPositionRestoresStartingFENAfterMove() {
        moveQueenToD7()
        waitForFEN(Self.queenD7FEN)

        resetPosition()

        XCTAssertTrue(square("d3").label.contains("White queen, d3"))
        XCTAssertTrue(square("d7").label.contains("Empty, d7"))
    }

    private func moveQueenToD7(targetOffset: CGVector = CGVector(dx: 0.5, dy: 0.5)) {
        tapSquare("d3")
        tapSquare("d7", offset: targetOffset)
    }

    private func playKnightCycleHistory() {
        for _ in 0..<5 {
            tapSquare("g1")
            tapSquare("f3")
            tapSquare("g8")
            tapSquare("f6")
            tapSquare("f3")
            tapSquare("g1")
            tapSquare("f6")
            tapSquare("g8")
        }
    }

    private func toggleMoveListScrollBars() {
        let toggle = element("Workbench.moveListScrollBarsToggle")
        assertExists(toggle)
        toggle.click()
    }

    private func resetPosition() {
        let resetButton = app.buttons["Workbench.resetPosition"]
        assertExists(resetButton)
        XCTAssertTrue(resetButton.isEnabled)
        resetButton.tap()
        waitForFEN(Self.startingFEN)
    }

    private func setFEN(_ fen: String) {
        let editor = fenEditor()
        editor.click()
        app.typeKey("a", modifierFlags: .command)
        app.typeText(fen)
        waitForFEN(fen)
    }

    private func selectMoveListLayout(_ layoutName: String) {
        let picker = element("Workbench.moveListLayoutPicker")
        assertExists(picker)

        if picker.value as? String == layoutName {
            return
        }

        picker.click()
        let menuItem = app.menuItems[layoutName]
        assertExists(menuItem, message: "Missing move-list layout menu item \(layoutName)")
        menuItem.click()
        waitForValue(layoutName, in: picker)
    }

    private func openWindowIfNeeded() {
        if element("Workbench.fenEditor").waitForExistence(timeout: 1) {
            return
        }

        app.typeKey("n", modifierFlags: .command)
    }

    private func tapSquare(_ coordinate: String, offset: CGVector = CGVector(dx: 0.5, dy: 0.5)) {
        square(coordinate).coordinate(withNormalizedOffset: offset).tap()
    }

    private func square(_ coordinate: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = element("ChessUI.square.\(coordinate)")
        assertExists(element, message: "Missing square \(coordinate)", file: file, line: line)
        return element
    }

    private func fenEditor(timeout: TimeInterval = 2, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let editor = element("Workbench.fenEditor")
        assertExists(editor, timeout: timeout, message: "Missing FEN editor", file: file, line: line)
        return editor
    }

    private func waitForFEN(
        _ expected: String,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let editor = fenEditor(timeout: timeout, file: file, line: line)
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }
            return Self.normalizedText(from: element) == expected
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: editor)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected FEN \(expected), got \(Self.normalizedText(from: editor))",
            file: file,
            line: line
        )
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func menuActionItem(_ title: String) -> XCUIElement {
        let predicate = NSPredicate(format: "title == %@", title)
        return app.menuItems.matching(predicate).firstMatch
    }

    private func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        message: String = "Expected element to exist",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !element.exists {
            XCTAssertTrue(element.waitForExistence(timeout: timeout), message, file: file, line: line)
        }
    }

    private func waitForHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        message: String = "Expected element to be hittable",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }

            return element.exists && element.isHittable
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message, file: file, line: line)
    }

    private func waitForNonExistence(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        message: String = "Expected element not to exist",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }

            return !element.exists
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message, file: file, line: line)
    }

    private func assertElementIsNearTop(
        _ element: XCUIElement,
        of container: XCUIElement,
        maximumTopPadding: CGFloat = 24,
        minimumBottomPadding: CGFloat = 72,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForNonEmptyFrame(container, file: file, line: line)
        waitForNonEmptyFrame(element, file: file, line: line)

        let topPadding = element.frame.minY - container.frame.minY
        let bottomPadding = container.frame.maxY - element.frame.maxY
        XCTAssertLessThanOrEqual(topPadding, maximumTopPadding, "Expected move to start near the top of the list", file: file, line: line)
        XCTAssertGreaterThanOrEqual(bottomPadding, minimumBottomPadding, "Expected unused space below short move history", file: file, line: line)
    }

    private func assertElementIsNearLeading(
        _ element: XCUIElement,
        of container: XCUIElement,
        maximumLeadingPadding: CGFloat = 24,
        minimumTrailingPadding: CGFloat = 120,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForNonEmptyFrame(container, file: file, line: line)
        waitForNonEmptyFrame(element, file: file, line: line)

        let leadingPadding = element.frame.minX - container.frame.minX
        let trailingPadding = container.frame.maxX - element.frame.maxX
        XCTAssertLessThanOrEqual(leadingPadding, maximumLeadingPadding, "Expected move to start near the leading edge of the list", file: file, line: line)
        XCTAssertGreaterThanOrEqual(trailingPadding, minimumTrailingPadding, "Expected unused space after short horizontal move history", file: file, line: line)
    }

    private func assertElementIsHorizontallyInside(
        _ element: XCUIElement,
        of container: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForNonEmptyFrame(container, file: file, line: line)
        waitForNonEmptyFrame(element, file: file, line: line)

        XCTAssertGreaterThanOrEqual(element.frame.minX, container.frame.minX - 1, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxX, container.frame.maxX + 1, file: file, line: line)
    }

    private func assertHorizontalMoveListStripAlignsWithBoardCard(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let strip = element("Workbench.horizontalMoveListStrip")
        let topLeftSquare = square("a8", file: file, line: line)
        let topRightSquare = square("h8", file: file, line: line)
        let boardCardPadding: CGFloat = 14

        assertExists(strip, message: "Missing horizontal move-list strip", file: file, line: line)
        waitForNonEmptyFrame(strip, file: file, line: line)
        waitForNonEmptyFrame(topLeftSquare, file: file, line: line)
        waitForNonEmptyFrame(topRightSquare, file: file, line: line)

        XCTAssertEqual(
            strip.frame.minX,
            topLeftSquare.frame.minX - boardCardPadding,
            accuracy: 2,
            "Horizontal move-list strip should align with the board card leading edge",
            file: file,
            line: line
        )
        XCTAssertEqual(
            strip.frame.maxX,
            topRightSquare.frame.maxX + boardCardPadding,
            accuracy: 2,
            "Horizontal move-list strip should align with the board card trailing edge",
            file: file,
            line: line
        )
    }

    private func waitForValue(
        _ expected: String,
        in element: XCUIElement,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }
            return element.value as? String == expected
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected value \(expected), got \((element.value as? String) ?? "<nil>")",
            file: file,
            line: line
        )
    }

    private func waitForText(
        _ expected: String,
        in element: XCUIElement,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }
            return Self.normalizedText(from: element) == expected
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected text \(expected), got \(Self.normalizedText(from: element))",
            file: file,
            line: line
        )
    }

    private func assertEvaluationBarScreenshotHasLightAndDarkSegments(
        _ bar: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            waitForNonEmptyFrame(bar, file: file, line: line)
            let bitmap = try Self.rgbaBitmap(from: bar.screenshot().pngRepresentation)
            let pixelCount = bitmap.width * bitmap.height
            var lightPixels = 0
            var darkPixels = 0

            for index in stride(from: 0, to: bitmap.pixels.count, by: 4) {
                let red = bitmap.pixels[index]
                let green = bitmap.pixels[index + 1]
                let blue = bitmap.pixels[index + 2]
                let alpha = bitmap.pixels[index + 3]

                guard alpha > 0 else { continue }

                if red > 210 && green > 210 && blue > 210 {
                    lightPixels += 1
                } else if red < 80 && green < 80 && blue < 80 {
                    darkPixels += 1
                }
            }

            let lightRatio = Double(lightPixels) / Double(pixelCount)
            let darkRatio = Double(darkPixels) / Double(pixelCount)
            XCTAssertGreaterThan(lightRatio, 0.10, "Evaluation bar screenshot had too little light segment", file: file, line: line)
            XCTAssertGreaterThan(darkRatio, 0.10, "Evaluation bar screenshot had too little dark segment", file: file, line: line)
        } catch {
            XCTFail("Could not inspect evaluation bar screenshot: \(error)", file: file, line: line)
        }
    }

    private func assertBoardScreenshotIsNotBlank(
        _ board: XCUIElement,
        themeName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            waitForNonEmptyFrame(board, file: file, line: line)
            let bitmap = try Self.rgbaBitmap(from: board.screenshot().pngRepresentation)
            let pixelCount = bitmap.width * bitmap.height
            var nonWhitePixels = 0

            for index in stride(from: 0, to: bitmap.pixels.count, by: 4) {
                let red = bitmap.pixels[index]
                let green = bitmap.pixels[index + 1]
                let blue = bitmap.pixels[index + 2]
                let alpha = bitmap.pixels[index + 3]

                if alpha > 0 && !(red > 245 && green > 245 && blue > 245) {
                    nonWhitePixels += 1
                }
            }

            let nonWhiteRatio = Double(nonWhitePixels) / Double(pixelCount)
            XCTAssertGreaterThan(
                nonWhiteRatio,
                0.20,
                "Board screenshot was mostly white after selecting \(themeName)",
                file: file,
                line: line
            )
        } catch {
            XCTFail("Could not inspect board screenshot after selecting \(themeName): \(error)", file: file, line: line)
        }
    }

    private func waitForNonEmptyFrame(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }
            return !element.frame.isEmpty
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected non-empty frame", file: file, line: line)
    }

    private func waitForFrameOrientation(
        _ element: XCUIElement,
        isHorizontal: Bool,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { element, _ in
            guard let element = element as? XCUIElement else {
                return false
            }

            if isHorizontal {
                return element.frame.width > element.frame.height
            }

            return element.frame.height > element.frame.width
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(isHorizontal ? "horizontal" : "vertical") frame, got \(element.frame)",
            file: file,
            line: line
        )
    }

    private static func normalizedText(from element: XCUIElement) -> String {
        let rawValue = (element.value as? String) ?? element.label
        return rawValue.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private func assertFrame(
        _ actual: CGRect,
        isCloseTo expected: CGRect,
        accuracy: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.origin.x, expected.origin.x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.origin.y, expected.origin.y, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.size.width, expected.size.width, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.size.height, expected.size.height, accuracy: accuracy, file: file, line: line)
    }

    private static func rgbaBitmap(from png: Data) throws -> (width: Int, height: Int, pixels: [UInt8]) {
        guard let source = CGImageSourceCreateWithData(png as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ScreenshotError.imageDecodingFailed
        }

        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ScreenshotError.bitmapCreationFailed
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (width, height, pixels)
    }

    private enum ScreenshotError: Error {
        case imageDecodingFailed
        case bitmapCreationFailed
    }
}
