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
        app.assertTextVisibilityCount(textToFind: orders[0].id)
        app.assertElementExistsOnCell(mainCell: orders[0].id, elementToFind: orders[0].product_id)
        app.assertCorrectCellCountDisplayed(expectedCount: products.count, actualCount: app.tables.cells.count)
        
 //       let TextVisibilityCount = try app.getTextVisibilityCount(text: orders[0].number)
//
  //      XCTAssertTrue(numberVisibilityCount == 1, "Expecting order number to appear once, appeared \(nameVisibilityCount) times instead!")
//        XCTAssertEqual(orders.count, app.tables.cells.count, "Expecting \(orders.count) orders, got \(app.tables.cells.count) instead!")
 //       XCTAssertTrue(try verifyProductsForOrder(id: orders[0].id, product: orders[0].product_id), "Products do not exist for order!")

        return self
    }
    
    public func verifyOrdersScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}
