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

        XCTAssertTrue(element("ChessUI.legalMove.e3").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.legalMove.e4").waitForExistence(timeout: 2))

        tapSquare("e4")

        XCTAssertEqual(lastMoveLabel(), "e2e4")
        XCTAssertTrue(element("ChessUI.lastMove.e2").waitForExistence(timeout: 2))
        XCTAssertTrue(element("ChessUI.lastMove.e4").waitForExistence(timeout: 2))
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

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}

private extension XCUIElement {
    func tapCenter() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
