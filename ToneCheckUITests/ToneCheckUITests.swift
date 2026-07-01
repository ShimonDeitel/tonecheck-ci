import XCTest

final class ToneCheckUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launch(pro: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["TONECHECK_NO_SK"] = "1"
        if pro { app.launchEnvironment["TONECHECK_FORCE_PRO"] = "1" }
        app.launch()
        return app
    }

    func testTabsExistAndSwitch() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Check"].waitForExistence(timeout: 5))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
    }

    func testCheckTabHasTextEditor() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Check"].waitForExistence(timeout: 5))
        // Check tab should be visible
        XCTAssertTrue(app.buttons["Check Tone"].waitForExistence(timeout: 5))
    }
}
