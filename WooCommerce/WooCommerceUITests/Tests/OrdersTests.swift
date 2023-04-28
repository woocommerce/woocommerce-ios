import UITestsFoundation
import XCTest

final class OrdersTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.login()
    }

    func test_load_orders_screen() throws {
        let orders = try GetMocks.readOrdersData()

        try TabNavComponent().goToOrdersScreen()
            .verifyOrdersScreenLoaded()
            .verifyOrdersList(orders: orders)
            .tapOrder(byOrderNumber: orders[0].number)
            .verifySingleOrder(order: orders[0])
            .goBackToOrdersScreen()
            .verifyOrdersScreenLoaded()
    }

    func test_create_new_order() throws {
        let order = try GetMocks.readSingleOrderData()

        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .editOrderStatus()
            .addProduct(byName: "Black Coral shades")
            .addCustomerDetails(name: order.billing.first_name)
            .addShipping(amount: order.shipping_lines[0].total, name: order.shipping_lines[0].method_title)
            .addFee(amount: order.fee_lines[0].amount)
            .addCustomerNote(order.customer_note)
            .createOrder()
            .verifySingleOrderScreenLoaded()
            .goBackToOrdersScreen()
            .verifyOrdersScreenLoaded()
    }

    func test_load_existing_order() throws {
        let orders = try GetMocks.readOrdersData()

        try TabNavComponent().goToOrdersScreen()
            .tapOrder(byOrderNumber: orders[0].number)
            .tapEditOrderButton()
            .checkForExistingOrderTitle(byOrderNumber: orders[0].number)
            .checkForExistingProducts(byName: orders[0].line_items.map { $0.name })
            .closeEditingFlow()
            .verifySingleOrderScreenLoaded()
    }

    func test_cancel_order_creation() throws {
        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .cancelOrderCreation()
            .verifyOrdersScreenLoaded()
    }
}
