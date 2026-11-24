import UITestsFoundation
import XCTest
import UIKit

@MainActor
final class OrdersTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchAndLogIn() throws {
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.login()
    }

    let customerNote = "New customer note"

    func test_load_orders_screen() throws {
        try launchAndLogIn()
        let orders = try GetMocks.readOrdersData()

        try TabNavComponent().goToOrdersScreen()
            .verifyOrdersScreenLoaded()
            .verifyOrdersList(orders: orders)
            .tapOrder(byOrderNumber: orders[0].number)
            .verifySingleOrder(order: orders[0])
            .goBackToOrdersScreen()
            .verifyOrdersScreenLoaded()
    }

    func test_order_list_header_remains_visible_when_scrolling() throws {
        // Given
        try launchAndLogIn()
        try TabNavComponent().goToOrdersScreen()
            .verifyOrdersScreenLoaded()
        let app = XCUIApplication()
        let tableView = app.tables["orders-table-view"]
        let filterButton = app.buttons["orders-filter-button"]

        // When
        tableView.swipeUp()

        // Then
        XCTAssertTrue(filterButton.isHittable, "The order-list header should remain fixed above the scrolling table.")
    }

    func test_create_new_order() throws {
        /// Tracked in WOOMOB-1904
        /// Temporarily skipping until resolved
        /// Failing on iPad on CI - `secondary-order-address-form` doesn't appear on switch toggle ON.
        try XCTSkipIf(
            UIDevice.current.userInterfaceIdiom == .pad,
            "Skipped on iPad simulators due to CI flakiness; runs on iPhone simulator."
        )

        try launchAndLogIn()
        let order = try GetMocks.readSingleOrderData()

        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .addProduct(byName: "Black Coral shades")
            .addCustomerDetails(name: order.billing.first_name)
            .addShipping(amount: order.shipping_lines[0].total, name: order.shipping_lines[0].method_title)
            .addCustomAmount(amount: order.fee_lines[1].amount)
            .addCustomerNote(order.customer_note)
            .createOrder()
            .verifySingleOrderScreenLoaded()
            .goBackToOrdersScreen()
            .verifyOrdersScreenLoaded()
    }

    func test_load_existing_order() throws {
        try launchAndLogIn()
        let orders = try GetMocks.readOrdersData()

        try TabNavComponent().goToOrdersScreen()
            .tapOrder(byOrderNumber: orders[0].number)
            .tapEditOrderButton()
            .checkForExistingOrderTitle(byOrderNumber: orders[0].number)
            .checkForExistingProducts(byName: orders[0].line_items.map { $0.name })
            .closeEditingFlow()
            .verifySingleOrderScreenLoaded()
    }

    func test_add_note_to_existing_order() throws {
        try launchAndLogIn()
        let orders = try GetMocks.readOrdersData()

        try TabNavComponent().goToOrdersScreen()
            .tapOrder(byOrderNumber: orders[0].number)
            .tapEditOrderButton()
            .openCustomerNoteScreen()
            .enterNote(customerNote)
            .verifyNoteAdded(customerNote)
    }

    func test_cancel_order_creation() throws {
        try launchAndLogIn()
        try TabNavComponent().goToOrdersScreen()
            .startOrderCreation()
            .cancelOrderCreation()
            .verifyOrdersScreenLoaded()
    }
}
