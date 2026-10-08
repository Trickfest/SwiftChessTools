//
// SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
//
// See NOTICE.md for upstream attribution and license details.
//
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import XCTest

final class ChessUIHarnessUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testHistoricalSelectionScrollsVerticallyAndSynchronizesBoard() {
        exerciseHistory(horizontal: false)
    }

    func testHistoricalSelectionScrollsHorizontallyAndSynchronizesBoard() {
        exerciseHistory(horizontal: true)
    }

    func testVerticalMoveNumbersStayOnOneLineAndKeepColumnsAligned() {
        for startingNumber in [99, 999] {
            app.launchEnvironment["HISTORY_FULL_MOVE_NUMBER"] = "\(startingNumber)"
            launchHistory(horizontal: false)
            app.buttons["One"].tap()
            expectMoveVisible(1)
            expectMoveVisible(3)

            // Match SwiftUI's locale-aware numeric interpolation, including
            // the grouping separator used for four-digit labels.
            let firstNumber = app.staticTexts["\(startingNumber.formatted())."]
            let nextNumber = app.staticTexts["\((startingNumber + 1).formatted())."]
            XCTAssertTrue(firstNumber.exists)
            XCTAssertTrue(nextNumber.exists, app.debugDescription)
            XCTAssertLessThanOrEqual(firstNumber.frame.height, element("ChessUI.moveList.move.1").frame.height)
            XCTAssertLessThanOrEqual(nextNumber.frame.height, element("ChessUI.moveList.move.3").frame.height)
            XCTAssertEqual(firstNumber.frame.maxX, nextNumber.frame.maxX, accuracy: 1)
            XCTAssertEqual(element("ChessUI.moveList.move.1").frame.minX,
                           element("ChessUI.moveList.move.3").frame.minX, accuracy: 1)

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Move numbers \(startingNumber) and \(startingNumber + 1)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
    }

    func testLegacyMoveListsStillFollowNewestMove() {
        for horizontal in [false, true] {
            launchHistory(horizontal: horizontal, legacy: true)
            expectHistory("Ply 1, count 100")
            expectMoveVisible(100)
            app.buttons["Grow"].tap()
            expectHistory("Ply 1, count 101")
            expectMoveVisible(101)
        }
    }

    func testHistoryJumpCancelsAnActiveDragWithoutReportingAMove() {
        launchHistory(horizontal: false)
        app.buttons["Jump on drag"].tap()
        dragSquare("g1", to: "f3")
        expectHistory("Ply 1, count 100")
        waitForLabel("Attempts 0", in: element("Harness.historyAttempts"))
        XCTAssertTrue(square("f3").label.contains("White knight"))
        XCTAssertTrue(square("g1").label.contains("Empty"))
        // A fresh gesture in the new game still reports normally.
        dragSquare("b8", to: "c6")
        waitForLabel("Attempts 1", in: element("Harness.historyAttempts"))
    }

    private func exerciseHistory(horizontal: Bool) {
        launchHistory(horizontal: horizontal)
        expectMoveVisible(100)
        app.buttons["One"].tap()
        expectHistory("Ply 1, count 100")
        expectMoveVisible(1)
        XCTAssertTrue(element("ChessUI.moveList.move.1").isSelected)
        XCTAssertTrue(square("f3").label.contains("White knight"))
        XCTAssertTrue(element("ChessUI.lastMove.g1").exists)
        XCTAssertTrue(element("ChessUI.lastMove.f3").exists)
        app.buttons["Grow"].tap()
        expectHistory("Ply 1, count 101")
        expectMoveVisible(1)
        XCTAssertTrue(square("f3").label.contains("White knight"))
        // The transparent padding of an unselected cell is interactive too.
        element("ChessUI.moveList.move.2")
            .coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        expectHistory("Ply 2, count 101")
        XCTAssertTrue(element("ChessUI.moveList.move.2").isSelected)
        XCTAssertTrue(square("f6").label.contains("Black knight"))
        XCTAssertTrue(element("ChessUI.lastMove.f6").exists)
        app.buttons["Middle"].tap()
        expectMoveVisible(50)
        app.buttons["Replace"].tap()
        expectHistory("Ply 50, count 101")
        expectMoveVisible(50)
        XCTAssertTrue(element("ChessUI.moveList.move.50").label.contains("Nc6"))
        XCTAssertTrue(square("c6").label.contains("Black knight"))
        app.buttons["ChessUI.moveNavigation.end"].tap()
        expectMoveVisible(101)
        app.buttons["ChessUI.moveNavigation.start"].tap()
        expectHistory("Ply 0, count 101")
        expectMoveVisible(1)
        XCTAssertFalse(element("ChessUI.moveList.move.1").isSelected)
        XCTAssertFalse(element("ChessUI.lastMove.c3").exists)
        XCTAssertTrue(square("b1").label.contains("White knight"))
        // Selecting a piece is transient UI state; a history jump clears it.
        square("b1").tapCenter()
        XCTAssertTrue(element("ChessUI.legalMove.c3").exists)
        app.buttons["One"].tap()
        XCTAssertFalse(element("ChessUI.legalMove.c3").exists)
        app.buttons["Reset"].tap()
        expectHistory("Ply 0, count 0")
        XCTAssertTrue(element("ChessUI.moveList.empty").exists)
        XCTAssertFalse(app.buttons["ChessUI.moveNavigation.next"].isEnabled)
    }

    private func launchHistory(horizontal: Bool, legacy: Bool = false) {
        app.terminate()
        app.launchEnvironment["CHESS_UI_HARNESS_HISTORY"] = "1"
        app.launchEnvironment["HISTORY_HORIZONTAL"] = horizontal ? "1" : "0"
        app.launchEnvironment["HISTORY_LEGACY"] = legacy ? "1" : "0"
        app.launch()
        XCTAssertTrue(element("Harness.historyState").waitForExistence(timeout: 5))
    }

    private func expectHistory(_ label: String) {
        waitForLabel(label, in: element("Harness.historyState"))
    }

    private func expectMoveVisible(_ ply: Int) {
        let move = element("ChessUI.moveList.move.\(ply)")
        // With a nil title, SwiftUI coalesces the outer list and scroll view's
        // accessibility nodes; the public list identifier owns the viewport.
        let scroll = element("ChessUI.moveList")
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard move.exists, scroll.exists else { return false }
            let intersection = move.frame.intersection(scroll.frame)
            return !intersection.isNull && intersection.width >= move.frame.width - 1
                && intersection.height >= move.frame.height - 1
        }, object: nil)
        let result = XCTWaiter.wait(for: [visible], timeout: 5)
        if result != .completed {
            let details = XCTAttachment(string: app.debugDescription)
            details.name = "History accessibility tree"
            details.lifetime = .keepAlways
            add(details)
        }
        XCTAssertEqual(result, .completed,
                       "Ply \(ply) should be fully visible in the move list")
    }

    func testNavigationButtonsReportDestinationsAndRespectBoundaries() {
        launchNavigation()
        let start = app.buttons["ChessUI.moveNavigation.start"]
        let previous = app.buttons["ChessUI.moveNavigation.previous"]
        let next = app.buttons["ChessUI.moveNavigation.next"]
        let end = app.buttons["ChessUI.moveNavigation.end"]
        XCTAssertFalse(start.isEnabled)
        XCTAssertFalse(previous.isEnabled)
        XCTAssertTrue(next.isEnabled)
        XCTAssertTrue(end.isEnabled)
        XCTAssertEqual(start.label, "Position Start")
        XCTAssertEqual(previous.label, "Previous Move")
        XCTAssertEqual(next.label, "Next Move")
        XCTAssertEqual(end.label, "Line End")
        for button in [start, previous, next, end] {
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height, 48)
        }
        XCTAssertLessThan(start.frame.maxX, previous.frame.minX)
        XCTAssertLessThan(previous.frame.maxX, next.frame.minX)
        XCTAssertLessThan(next.frame.maxX, end.frame.minX)
        next.tap()
        expectNavigation("Ply 1, count 4, requests 1, last 1")
        previous.tap()
        expectNavigation("Ply 0, count 4, requests 2, last 0")
        end.tap()
        expectNavigation("Ply 4, count 4, requests 3, last 4")
        XCTAssertFalse(next.isEnabled)
        XCTAssertFalse(end.isEnabled)
        start.tap()
        expectNavigation("Ply 0, count 4, requests 4, last 0")
        retainNavigationScreenshot()
    }

    func testNavigationRemainsCallerControlledAndHandlesLineGrowth() {
        launchNavigation()
        let accepts = app.switches["Harness.acceptNavigation"]
        accepts.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(accepts.value as? String, "0")
        app.buttons["ChessUI.moveNavigation.next"].tap()
        expectNavigation("Ply 0, count 4, requests 1, last 1")
        app.buttons["ChessUI.moveNavigation.next"].tap()
        expectNavigation("Ply 0, count 4, requests 2, last 1")
        accepts.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(accepts.value as? String, "1")
        app.buttons["ChessUI.moveNavigation.next"].tap()
        app.buttons["Grow"].tap()
        expectNavigation("Ply 1, count 5, requests 3, last 1")
        app.buttons["ChessUI.moveNavigation.end"].tap()
        expectNavigation("Ply 5, count 5, requests 4, last 5")
    }

    func testNavigationEmptyAndInvalidDisableAllButtonsAtLargeTextSize() {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["CHESS_UI_HARNESS_NAVIGATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["ChessUI.moveNavigation.next"].waitForExistence(timeout: 5))
        app.buttons["Empty"].tap()
        for suffix in ["start", "previous", "next", "end"] {
            XCTAssertFalse(app.buttons["ChessUI.moveNavigation.\(suffix)"].isEnabled)
        }
        app.buttons["Reset"].tap()
        app.buttons["Invalid"].tap()
        for suffix in ["start", "previous", "next", "end"] {
            XCTAssertFalse(app.buttons["ChessUI.moveNavigation.\(suffix)"].isEnabled)
        }
        expectNavigation("Ply -1, count 4, requests 0, last -1")
        retainNavigationScreenshot()
    }

    private func launchNavigation() {
        app.terminate()
        app.launchEnvironment["CHESS_UI_HARNESS_NAVIGATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["ChessUI.moveNavigation.next"].waitForExistence(timeout: 5))
    }

    private func expectNavigation(_ text: String) {
        let state = app.staticTexts["Harness.navigationState"]
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", text), object: state)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 3), .completed, "Actual state: \(state.label)")
    }

    private func retainNavigationScreenshot() {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Move navigation control"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSmallArtworkPreservesSquareFramesDragAndPromotion() {
        let originalFrame = square("e2").frame
        app.terminate()
        app.launchEnvironment["CHESS_UI_HARNESS_PIECE_SCALE"] = "0.50"
        app.launch()
        XCTAssertEqual(square("e2").frame.width, originalFrame.width, accuracy: 0.5)
        XCTAssertEqual(square("e2").frame.height, originalFrame.height, accuracy: 0.5)
        dragSquare("g1", to: "f3")
        XCTAssertEqual(lastMoveLabel(), "g1f3")
        app.buttons["Harness.promotionScenario"].tap()
        tapSquare("e7")
        tapSquare("e8")
        let queen = app.buttons["ChessUI.promotion.queen"]
        XCTAssertTrue(queen.waitForExistence(timeout: 2))
        queen.tap()
        XCTAssertEqual(lastMoveLabel(), "e7e8q")
        XCTAssertTrue(square("e8").label.contains("White queen, e8"))
    }

    func testTapMoveShowsLegalMovesAndLastMoveHighlight() {
        tapSquare("e2")

        let e3LegalMove = element("ChessUI.legalMove.e3")
        let e4LegalMove = element("ChessUI.legalMove.e4")
        XCTAssertTrue(e3LegalMove.waitForExistence(timeout: 2))
        XCTAssertTrue(e4LegalMove.waitForExistence(timeout: 2))
        XCTAssertTrue(e3LegalMove.label.contains("Legal move e3"))
        XCTAssertTrue(e4LegalMove.label.contains("Legal move e4"))

        tapSquare("e4")

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        let e2LastMove = element("ChessUI.lastMove.e2")
        let e4LastMove = element("ChessUI.lastMove.e4")
        XCTAssertTrue(e2LastMove.waitForExistence(timeout: 2))
        XCTAssertTrue(e4LastMove.waitForExistence(timeout: 2))
        XCTAssertTrue(e2LastMove.label.contains("Last move e2"))
        XCTAssertTrue(e4LastMove.label.contains("Last move e4"))
        XCTAssertTrue(square("e4").label.contains("White pawn, e4"))
    }

    func testNativeVoiceOverButtonsSelectAndMove() {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments.append("-forceNativeChessBoardAccessibilityControls")
        app.launch()

        let source = square("e2")
        XCTAssertEqual(source.elementType, .button)
        source.tap()

        let target = square("e4")
        XCTAssertEqual(target.elementType, .button)
        XCTAssertTrue(target.label.contains("legal destination"))
        target.tap()

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        XCTAssertTrue(square("e4").label.contains("White pawn, e4"))
    }

    func testInvalidMoveIsRejectedBeforeCallback() {
        tapSquare("e2")
        tapSquare("e5")

        XCTAssertEqual(lastMoveLabel(), "No moves yet")
        XCTAssertTrue(square("e2").label.contains("White pawn, e2"))
        XCTAssertTrue(square("e5").label.contains("Empty, e5"))
    }

    func testDragMoveUpdatesBoardAndFeedback() {
        dragSquare("g1", to: "f3")

        XCTAssertEqual(lastMoveLabel(), "g1f3")
        XCTAssertTrue(element("ChessUI.lastMove.g1").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.f3").waitForExistence(timeout: 2))
        XCTAssertTrue(square("f3").label.contains("White knight, f3"))
    }

    func testPromotionPickerAppliesSelectedPiece() {
        app.buttons["Harness.promotionScenario"].tap()

        tapSquare("e7")
        tapSquare("e8")

        let queenButton = app.buttons["ChessUI.promotion.queen"]
        XCTAssertTrue(queenButton.waitForExistence(timeout: 2))
        XCTAssertEqual(queenButton.label, "Promote to queen")
        XCTAssertEqual(app.buttons["ChessUI.promotion.rook"].label, "Promote to rook")
        XCTAssertEqual(app.buttons["ChessUI.promotion.bishop"].label, "Promote to bishop")
        XCTAssertEqual(app.buttons["ChessUI.promotion.knight"].label, "Promote to knight")
        queenButton.tap()

        XCTAssertEqual(lastMoveLabel(), "e7e8q")
        XCTAssertTrue(square("e8").label.contains("White queen, e8"))
        XCTAssertTrue(element("ChessUI.lastMove.e7").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.e8").waitForExistence(timeout: 2))
    }

    func testBlackPerspectiveKeepsLogicalDragMapping() {
        app.buttons["Harness.blackPerspective"].tap()

        dragSquare("e2", to: "e4")

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        XCTAssertTrue(square("e4").label.contains("White pawn, e4"))
        XCTAssertTrue(element("ChessUI.lastMove.e2").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.e4").waitForExistence(timeout: 2))
    }

    func testOutsideCoordinatesKeepBlackPerspectiveDragMapping() {
        let outsideCoordinates = app.buttons["Harness.outsideCoordinates"]
        XCTAssertTrue(outsideCoordinates.waitForExistence(timeout: 2))
        outsideCoordinates.tap()
        app.buttons["Harness.blackPerspective"].tap()

        dragSquare("e2", to: "e4")

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        XCTAssertTrue(square("e4").label.contains("White pawn, e4"))
        XCTAssertTrue(element("ChessUI.lastMove.e2").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.e4").waitForExistence(timeout: 2))
    }

    func testOutsideCoordinatesKeepTapMapping() {
        let outsideCoordinates = app.buttons["Harness.outsideCoordinates"]
        XCTAssertTrue(outsideCoordinates.waitForExistence(timeout: 2))
        outsideCoordinates.tap()

        tapSquare("e2")
        XCTAssertTrue(element("ChessUI.legalMove.e4").waitForExistence(timeout: 2))
        tapSquare("e4")

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        XCTAssertTrue(square("e4").label.contains("White pawn, e4"))
    }

    func testOutsideCoordinatesKeepPromotionPickerAligned() {
        let outsideCoordinates = app.buttons["Harness.outsideCoordinates"]
        XCTAssertTrue(outsideCoordinates.waitForExistence(timeout: 2))
        outsideCoordinates.tap()
        app.buttons["Harness.promotionScenario"].tap()

        tapSquare("e7")
        tapSquare("e8")

        let queenButton = app.buttons["ChessUI.promotion.queen"]
        XCTAssertTrue(queenButton.waitForExistence(timeout: 2))
        queenButton.tap()

        XCTAssertEqual(lastMoveLabel(), "e7e8q")
        XCTAssertTrue(square("e8").label.contains("White queen, e8"))
    }

    func testReadOnlyModeBlocksSelectionAndMoveReporting() {
        app.buttons["Harness.mode.readOnly"].tap()
        waitForLabel("Mode: readOnly", in: element("Harness.interactionMode"))

        tapSquare("e2")

        XCTAssertFalse(element("ChessUI.legalMove.e3").exists)
        XCTAssertFalse(element("ChessUI.legalMove.e4").exists)

        tapSquare("e4")

        XCTAssertEqual(lastMoveLabel(), "No moves yet")
        XCTAssertTrue(square("e2").label.contains("White pawn, e2"))
        XCTAssertTrue(square("e4").label.contains("Empty, e4"))
    }

    func testReportsIllegalAttemptsModeReportsIllegalMove() {
        app.buttons["Harness.mode.reportsIllegalAttempts"].tap()
        waitForLabel("Mode: reportsIllegalAttempts", in: element("Harness.interactionMode"))

        tapSquare("e2")
        tapSquare("e5")

        waitForLabel("Rejected e2e5", in: element("Harness.lastMove"))
        XCTAssertTrue(square("e2").label.contains("White pawn, e2"))
        XCTAssertTrue(square("e5").label.contains("Empty, e5"))
    }

    func testFreeSetupModeReportsOpponentPieceAttempts() {
        app.buttons["Harness.mode.freeSetup"].tap()
        waitForLabel("Mode: freeSetup", in: element("Harness.interactionMode"))

        tapSquare("e7")
        tapSquare("e5")

        waitForLabel("Rejected e7e5", in: element("Harness.lastMove"))
        XCTAssertTrue(square("e7").label.contains("Black pawn, e7"))
        XCTAssertTrue(square("e5").label.contains("Empty, e5"))
    }

    func testStatusEvaluationAndMoveListExposeAccessibility() {
        let statusText = element("ChessUI.gameStatus.text")
        let status = element("ChessUI.gameStatus")
        let evaluationBar = element("ChessUI.evaluationBar")
        let moveList = element("ChessUI.moveList")
        let moveListTitle = element("ChessUI.moveList.title")
        let blackMove = element("ChessUI.moveList.move.2")

        XCTAssertTrue(status.waitForExistence(timeout: 2))
        waitForLabel(
            "White to move. Draw claims available: fifty-move rule and threefold repetition",
            in: statusText
        )

        let fiftyMoveClaim = app.buttons["ChessUI.gameStatus.claim.fiftyMoveRule"]
        let threefoldClaim = app.buttons["ChessUI.gameStatus.claim.threefoldRepetition"]
        XCTAssertTrue(fiftyMoveClaim.waitForExistence(timeout: 2))
        XCTAssertTrue(threefoldClaim.waitForExistence(timeout: 2))
        XCTAssertEqual(fiftyMoveClaim.label, "Claim fifty-move draw")
        XCTAssertEqual(threefoldClaim.label, "Claim threefold repetition draw")

        fiftyMoveClaim.tap()
        waitForLabel("Claimed fifty-move rule", in: element("Harness.drawClaim"))

        XCTAssertTrue(evaluationBar.waitForExistence(timeout: 2))
        XCTAssertEqual(evaluationBar.label, "Evaluation")
        XCTAssertEqual(evaluationBar.value as? String, "Black mate in 2")

        XCTAssertTrue(moveList.waitForExistence(timeout: 2))
        XCTAssertTrue(moveListTitle.waitForExistence(timeout: 2))
        XCTAssertEqual(moveListTitle.label, "Harness moves")
        XCTAssertTrue(blackMove.waitForExistence(timeout: 2))
        XCTAssertTrue(blackMove.label.contains("1. Black e5"))
        XCTAssertEqual(blackMove.value as? String, "e7e5")
    }

    private func tapSquare(_ coordinate: String) {
        square(coordinate).tapCenter()
    }

    private func dragSquare(_ source: String, to target: String) {
        let sourceElement = square(source)
        let targetElement = square(target)
        sourceElement.press(forDuration: 0.1, thenDragTo: targetElement)
    }

    private func square(_ coordinate: String) -> XCUIElement {
        let element = element("ChessUI.square.\(coordinate)")
        XCTAssertTrue(element.waitForExistence(timeout: 2), "Missing square \(coordinate)")
        return element
    }

    private func lastMoveLabel() -> String {
        let label = element("Harness.lastMove")
        XCTAssertTrue(label.waitForExistence(timeout: 2))
        return label.label
    }

    private func waitForLabel(_ expectedLabel: String, in element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 2))
        let predicate = NSPredicate(format: "label == %@", expectedLabel)
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: 2)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}

private extension XCUIElement {
    func tapCenter() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
