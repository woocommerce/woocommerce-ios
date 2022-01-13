import UITestsFoundation
import XCTest
import Networking

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
            print(orders) // just for human validation

            _ = try TabNavComponent()
                .gotoOrdersScreen()
                .verifyOrdersScreenLoaded()
                .verifyOrdersList(orders: orders) //parameter, variable
                .selectOrder(atIndex: 0)//orders[0].id)
                .verifySingleOrder(order: orders[0])
                .goBackToOrdersScreen()
                .verifyOrdersScreenLoaded()
        }
    }
