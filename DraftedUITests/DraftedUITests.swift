import XCTest

final class DraftedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingCanReachHome() throws {
        let app = XCUIApplication()
        app.launch()

        for _ in 0..<5 {
            let continueButton = app.buttons["Continue"]
            if continueButton.waitForExistence(timeout: 2) {
                continueButton.tap()
            }
        }

        let finalButton = app.buttons["Create or Join"]
        if finalButton.waitForExistence(timeout: 2) {
            finalButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Drafted"].waitForExistence(timeout: 4))
    }
}

