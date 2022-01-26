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

        try TabNavComponent().goToOrdersScreen()
            .verifyOrdersScreenLoaded()
            .verifyOrdersList(orders: orders)
            .selectOrder(byOrderNumber: orders[0].number)
            .verifySingleOrder(order: orders[0])
            .goBackToOrdersScreen()
            .verifyOrdersScreenLoaded()
    }
}
