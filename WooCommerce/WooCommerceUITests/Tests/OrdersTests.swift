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

    func testOrdersScreenLoads() throws {
            let orders = try GetMocks.readOrdersData()

            _ = try TabNavComponent()
                .gotoOrdersScreen()
                .verifyOrdersScreenLoaded()
                .verifyOrdersList(orders: number)
                .selectOrder(byName: orders[0].id)
                .verifyOrderOnSingleOrderScreen(order: orders[0])
                .goBackToOrderList()
                .verifyOrderScreenLoaded()
        }
    }
}
