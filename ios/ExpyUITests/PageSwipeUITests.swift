import XCTest

/// Drives real swipes in the simulator: pages change on a horizontal swipe,
/// but not when the swipe starts on a chip row that scrolls sideways.
final class PageSwipeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-startTab", "1", "-noSplash"]
        app.launch()
    }

    private var tapPage: XCUIElement { app.staticTexts["How much?"] }
    private var historyPage: XCUIElement { app.staticTexts["Expenses"] }

    func testSwipeLeftAndRightChangesPage() {
        XCTAssertTrue(tapPage.waitForExistence(timeout: 5))
        app.buttons["5"].swipeLeft()
        // The selected tab changes at once; Analytics can take a moment to draw in a debug build.
        XCTAssertTrue(app.tabBars.buttons["Analytics"].waitForSelection(timeout: 3), "swipe left from Tap should select Analytics")
        XCTAssertTrue(app.staticTexts["Avg / day"].waitForExistence(timeout: 10), "Analytics should appear")
        XCTAssertFalse(tapPage.exists)
        app.swipeRight()
        XCTAssertTrue(tapPage.waitForExistence(timeout: 3), "swipe right should return to Tap")
        app.buttons["5"].swipeRight()
        XCTAssertTrue(historyPage.waitForExistence(timeout: 3), "swipe right from Tap should open History")
    }

    func testChipRowScrollsInsteadOfChangingPage() {
        XCTAssertTrue(tapPage.waitForExistence(timeout: 5))
        app.buttons["Transport"].firstMatch.swipeLeft()
        sleep(1)
        XCTAssertTrue(tapPage.exists, "swiping the category chips must not leave the Tap page")
    }

    func testTabBarStillWorks() {
        XCTAssertTrue(tapPage.waitForExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Quick Launch setup"].waitForExistence(timeout: 3))
    }

    func testCreditShowsCreditCategories() {
        XCTAssertTrue(tapPage.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Food"].firstMatch.exists)
        app.buttons["Credit"].tap()
        XCTAssertTrue(app.buttons["Salary"].firstMatch.waitForExistence(timeout: 3), "Credit should show credit categories")
        XCTAssertFalse(app.buttons["Food"].firstMatch.exists)
    }
}

private extension XCUIElement {
    func waitForSelection(timeout: TimeInterval) -> Bool {
        let selected = NSPredicate(format: "isSelected == true")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: selected, object: self)], timeout: timeout) == .completed
    }
}
