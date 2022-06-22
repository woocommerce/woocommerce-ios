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

    func test_load_orders_screen() throws {
        let orders = try GetMocks.readOrdersData()

        try TabNavComponent().goToOrdersScreen()
            .verifyOrdersScreenLoaded()
            .verifyOrdersList(orders: orders)
            .selectOrder(byOrderNumber: orders[0].number)
            .verifySingleOrder(order: orders[0])
            .goBackToOrdersScreen()
            .verifyOrdersScreenLoaded()
    }

    func test_create_new_order() throws {
        let products = try GetMocks.readProductsData()
        let order = try GetMocks.readNewOrderData()

        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .editOrderStatus()
            .addProduct(byName: products[0].name)
            .addCustomerDetails(name: "Mira")
            .addShipping(amount: "1.25", name: "Flat Rate")
            .addFee(amount: "2.34")
            .addCustomerNote(order.customer_note)
            .createOrder()
    }

    func test_cancel_order_creation() throws {
        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .cancelOrderCreation()
    }
}
