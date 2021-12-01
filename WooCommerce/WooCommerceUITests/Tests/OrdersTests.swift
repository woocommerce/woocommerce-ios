import UITestsFoundation
import XCTest

final class OrdersTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
    }

    // TODO: Write real test, this is a placeholder for now
    func testGotoOrdersScreen() throws {
        try LoginFlow.login()
        try TabNavComponent().gotoOrdersScreen()
        XCTAssert(try OrdersScreen().isLoaded)
    }
}
