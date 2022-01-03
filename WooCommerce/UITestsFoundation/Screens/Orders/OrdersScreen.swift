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
      //  app.assertCorrectCellCountDisplayed(expectedCount: orders.count, actualCount: app.tables.cells.count)
        XCTAssertEqual(orders.count, app.tables.cells.count, "Expecting \(orders.count) orders, got \(app.tables.cells.count) instead!") //orders.count counts the orders in the "orders" variable (from the mocks), while tables.cells.count counts the cells in the table, in the UI itself.
        app.assertTextVisibilityCount(textToFind: String(orders[0].id))
        //check an item from the mocks, make sure it appears on the screen. something like order id is good here, but it has to be a string
        //app.assertTextVisibilityCount(textToFind: String(orders[0].total)) // doesn't work because the Total isn't formatted in the mock, but is in the UI.
        app.assertTwoTextsAppearOnSameLabel(firstSubstring: String(orders[0].id), secondSubstring: orders[0].billing.first_name)
        // check that the accessibilityID has the correct id and first name
//        app.assertTextVisibilityCount(textToFind: orders[0].total)

        //        app.assertElementExistsOnCell(mainCell: orders[0].number, elementToFind: orders[0].product_id) // this one might not work, depending on the structure. Oh, nope. the product id won't display on this screen, it's on singleOrder screen.

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
