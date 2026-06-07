import ChessUI
import XCTest

final class ChessWorkbenchUITests: XCTestCase {
    private static let startingFEN = "5k2/1P2bn2/8/8/8/3Q4/3K4/8 w - - 0 1"
    private static let queenD7FEN = "5k2/1P1Qbn2/8/8/8/8/3K4/8 b - - 1 1"

    private var pieceSetNames: [String] {
        ChessPieceSet.availableSets.map(\.displayName)
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        waitForFEN(Self.startingFEN, timeout: 8)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testBoardRendersExpectedStartingPosition() {
        XCTAssertTrue(square("b7").label.contains("White pawn b7"))
        XCTAssertTrue(square("d3").label.contains("White queen d3"))
        XCTAssertTrue(square("d2").label.contains("White king d2"))
        XCTAssertTrue(square("e7").label.contains("Black bishop e7"))
        XCTAssertTrue(square("f7").label.contains("Black knight f7"))
        XCTAssertTrue(square("f8").label.contains("Black king f8"))
    }

    func testPieceSetPickerSelectsEveryBuiltInSet() {
        let picker = app.popUpButtons["Workbench.pieceSetPicker"]

        assertExists(picker)
        XCTAssertEqual(picker.value as? String, ChessPieceSet.artDecoMonochrome.displayName)

        for pieceSetName in pieceSetNames {
            picker.click()
            let menuItem = app.menuItems[pieceSetName]
            assertExists(menuItem, message: "Missing piece set menu item \(pieceSetName)")
            menuItem.click()
            XCTAssertEqual(picker.value as? String, pieceSetName)
        }
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
            XCTAssertTrue(square("d7").label.contains("White queen d7"))
            resetPosition()
        }
    }

    func testLegalMoveUpdatesFENField() {
        moveQueenToD7()

        waitForFEN(Self.queenD7FEN)
        XCTAssertTrue(square("d7").label.contains("White queen d7"))
    }

    func testInvalidMoveDoesNotUpdateFEN() {
        tapSquare("d3")
        tapSquare("e5")

        waitForFEN(Self.startingFEN)
        XCTAssertTrue(square("d3").label.contains("White queen d3"))
        XCTAssertTrue(square("e5").label.contains("Empty e5"))
    }

    func testShowD3MarkerDisplaysMarker() {
        app.buttons["Workbench.showD3Marker"].tap()

        assertExists(element("ChessUI.hint.d3"))
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

        XCTAssertTrue(square("d3").label.contains("White queen d3"))
        XCTAssertTrue(square("d7").label.contains("Empty d7"))
    }

    private func moveQueenToD7(targetOffset: CGVector = CGVector(dx: 0.5, dy: 0.5)) {
        tapSquare("d3")
        tapSquare("d7", offset: targetOffset)
    }

    private func resetPosition() {
        let resetButton = app.buttons["Workbench.resetPosition"]
        assertExists(resetButton)
        XCTAssertTrue(resetButton.isEnabled)
        resetButton.tap()
        waitForFEN(Self.startingFEN)
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
}
