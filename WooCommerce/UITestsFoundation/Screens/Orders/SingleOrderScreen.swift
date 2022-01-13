import ScreenObject
import XCTest

public final class SingleOrderScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    let tabBar = try! TabNavComponent()

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["summary-table-view-cell-title-label"]} ],
            app: app
        )
    }

    @discardableResult
    public func verifySingleOrder(order: OrderData) throws -> Self {
        app.assertTextVisibilityCount(textToFind: order.status, expectedCount: 1)
        //Expects 2 instances of first_name - one in Summary and one in Shipping details
        app.assertTextVisibilityCount(textToFind: order.billing.first_name, expectedCount: 2)
        app.assertElement(matching: "summary-table-view-cell", existsOnCellWithIdentifier: "\(order.billing.first_name) \(order.billing.last_name)")
        app.assertTextVisibilityCount(textToFind: order.total, expectedCount: 1)
        XCTAssertTrue(app.staticTexts[order.line_items[0].name].isFullyVisibleOnScreen(), "First product name is not visible on screen!")

        return self
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
