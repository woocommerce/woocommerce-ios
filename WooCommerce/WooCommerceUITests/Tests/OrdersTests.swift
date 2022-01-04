import UITestsFoundation
import XCTest

final class OrdersTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()
    }

    // TODO: Write real test, this is a placeholder for now
    func testGoToOrdersScreen() throws {
        try TabNavComponent().goToOrdersScreen()
        XCTAssert(try OrdersScreen().isLoaded)
    }
}
