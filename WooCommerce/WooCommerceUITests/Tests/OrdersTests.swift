import UITestsFoundation
import XCTest

final class OrdersTests: XCTestCase {

    let newServer = mockServer()
    override func setUpWithError() throws {

        continueAfterFailure = false
        try newServer.startWebServer()

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["disable-animations", "mocked-network-layer", "-ui_testing", "-mocks-port", "\(newServer.server.listenAddress.port)"]
        app.launch()
    }

    override func tearDown() {
        newServer.stopWebServer()
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
            .addProduct(byName: "Black Coral Shades")
            .addCustomerDetails(name: "order.billing.first_name")
            .addShipping(amount: order.shipping_lines[0].total, name: order.shipping_lines[0].method_title)
            .addFee(amount: order.fee_lines[0].amount)
            .addCustomerNote(order.customer_note)
            .createOrder()
            .verifySingleOrderScreenLoaded()
    }

    func test_cancel_order_creation() throws {
        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .cancelOrderCreation()
            .verifyOrdersScreenLoaded()
    }
}
