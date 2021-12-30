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

    // Check that SingleOrderScreen loads
    func test_load_single_order_screen() {
            //Select an order and verify the sections of the single order screen load.
        _ = try! TabNavComponent()
            .gotoOrdersScreen()
            .selectOrder(atIndex: 0)
            .verifySingleOrderScreenLoaded()
            // XCTAssert(singleOrder.isLoaded())
        }
    }
