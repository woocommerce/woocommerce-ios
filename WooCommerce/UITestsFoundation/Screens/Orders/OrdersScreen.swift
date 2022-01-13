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

    private var searchButton: XCUIElement { searchButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                searchButtonGetter,
                filterButtonGetter
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
    public func openSearchPane() throws -> OrderSearchScreen {
        searchButton.tap()
        return try OrderSearchScreen()
    }

    public func verifyOrdersList(orders: [OrderData]) throws -> Self {
        XCTAssertEqual(orders.count, app.tables.cells.count, "Expecting \(orders.count) orders, got \(app.tables.cells.count) instead!")
        app.assertTextVisibilityCount(textToFind: String(orders[0].id))
        app.assertTextVisibilityCount(textToFind: String(orders[0].total))
        app.assertLabelContains(firstSubstring: String(orders[0].id), secondSubstring: orders[0].billing.first_name)

        return self
    }

    public func verifyOrdersScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}
