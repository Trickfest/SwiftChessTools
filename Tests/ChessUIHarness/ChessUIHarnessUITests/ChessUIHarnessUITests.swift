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
        XCTAssertTrue(square("e4").label.contains("White pawn e4"))
    }

    func testInvalidMoveIsRejectedBeforeCallback() {
        tapSquare("e2")
        tapSquare("e5")

        XCTAssertEqual(lastMoveLabel(), "No moves yet")
        XCTAssertTrue(square("e2").label.contains("White pawn e2"))
        XCTAssertTrue(square("e5").label.contains("Empty e5"))
    }

    func testDragMoveUpdatesBoardAndFeedback() {
        dragSquare("g1", to: "f3")

        XCTAssertEqual(lastMoveLabel(), "g1f3")
        XCTAssertTrue(element("ChessUI.lastMove.g1").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.f3").waitForExistence(timeout: 2))
        XCTAssertTrue(square("f3").label.contains("White knight f3"))
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
        XCTAssertTrue(square("e8").label.contains("White queen e8"))
        XCTAssertTrue(element("ChessUI.lastMove.e7").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.e8").waitForExistence(timeout: 2))
    }

    func testBlackPerspectiveKeepsLogicalDragMapping() {
        app.buttons["Harness.blackPerspective"].tap()

        dragSquare("e2", to: "e4")

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        XCTAssertTrue(square("e4").label.contains("White pawn e4"))
        XCTAssertTrue(element("ChessUI.lastMove.e2").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.e4").waitForExistence(timeout: 2))
    }

    func testReadOnlyModeBlocksSelectionAndMoveReporting() {
        app.buttons["Harness.mode.readOnly"].tap()
        waitForLabel("Mode: readOnly", in: element("Harness.interactionMode"))

        tapSquare("e2")

        XCTAssertFalse(element("ChessUI.legalMove.e3").exists)
        XCTAssertFalse(element("ChessUI.legalMove.e4").exists)

        tapSquare("e4")

        XCTAssertEqual(lastMoveLabel(), "No moves yet")
        XCTAssertTrue(square("e2").label.contains("White pawn e2"))
        XCTAssertTrue(square("e4").label.contains("Empty e4"))
    }

    func testReportsIllegalAttemptsModeReportsIllegalMove() {
        app.buttons["Harness.mode.reportsIllegalAttempts"].tap()
        waitForLabel("Mode: reportsIllegalAttempts", in: element("Harness.interactionMode"))

        tapSquare("e2")
        tapSquare("e5")

        waitForLabel("Rejected e2e5", in: element("Harness.lastMove"))
        XCTAssertTrue(square("e2").label.contains("White pawn e2"))
        XCTAssertTrue(square("e5").label.contains("Empty e5"))
    }

    func testFreeSetupModeReportsOpponentPieceAttempts() {
        app.buttons["Harness.mode.freeSetup"].tap()
        waitForLabel("Mode: freeSetup", in: element("Harness.interactionMode"))

        tapSquare("e7")
        tapSquare("e5")

        waitForLabel("Rejected e7e5", in: element("Harness.lastMove"))
        XCTAssertTrue(square("e7").label.contains("Black pawn e7"))
        XCTAssertTrue(square("e5").label.contains("Empty e5"))
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
