import ScreenObject
import XCTest

public final class OrdersScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()

    private let searchButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-search-button"]
    }

    private let filterButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Filter"]
    }

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-type-sheet-button"]
    }

    private let newOrderCellGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["new_order_full_manual_order"]
    }

    private var searchButton: XCUIElement { searchButtonGetter(app) }

    /// Button (`+`) to create a new order or simple payment
    ///
    private var createButton: XCUIElement { createButtonGetter(app) }

    /// Button (on the Orders bottom sheet) to create a full manual order
    ///
    private var newOrderButton: XCUIElement { newOrderCellGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                searchButtonGetter,
                filterButtonGetter,
                createButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func selectOrder(atIndex index: Int) throws -> SingleOrderScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleOrderScreen()
    }

    @discardableResult
    public func selectOrder(byOrderNumber orderNumber: String) throws -> SingleOrderScreen {
        let orderNumberPredicate = NSPredicate(format: "label CONTAINS[c] %@", orderNumber)
        app.staticTexts.containing(orderNumberPredicate).firstMatch.tap()

        return try SingleOrderScreen()
    }

    @discardableResult
    public func openSearchPane() throws -> OrderSearchScreen {
        searchButton.tap()
        return try OrderSearchScreen()
    }

    @discardableResult
    public func verifyOrdersList(orders: [OrderData]) throws -> Self {
        let ordersTableView = app.tables.matching(identifier: "orders-table-view")
        XCTAssertEqual(orders.count, ordersTableView.cells.count, "Expecting '\(orders.count)' orders, got '\(app.tables.cells.count)' instead!")
        ordersTableView.element.assertTextVisibilityCount(textToFind: String(orders[0].id))
        ordersTableView.element.assertTextVisibilityCount(textToFind: String(orders[0].total))
        ordersTableView.element.assertLabelContains(firstSubstring: String(orders[0].id), secondSubstring: orders[0].billing.first_name)

        return self
    }

   @discardableResult
    public func verifyOrdersScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    /// Starts the order creation flow by navigating from the Orders screen to the New Order screen.
    /// - Returns: New Order screen object.
    @discardableResult
    public func startOrderCreation() throws -> NewOrderScreen {
        createButton.tap()
        newOrderButton.tap()
        return try NewOrderScreen()
    }
}
