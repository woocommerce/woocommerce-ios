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

        try TabNavComponent()
            .goToOrdersScreen()
    }

    func testOrdersScreenLoads() throws {
            let orders = try GetMocks.readOrdersData()

            try OrdersScreen()
                .verifyOrdersScreenLoaded()
                .verifyOrdersList(orders: orders)
                .selectOrder(byOrderNumber: orders[0].number)
                .verifySingleOrder(order: orders[0])
                .goBackToOrdersScreen()
                .verifyOrdersScreenLoaded()
    }
}
