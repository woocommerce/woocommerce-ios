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
        app.assertTextVisibilityCount(textToFind: order.status, expectedCount: 1) //checks that the Mock order status appears on the screen
        app.assertTextVisibilityCount(textToFind: order.billing.first_name, expectedCount: 2)

        // Check that the Mock first name ("Mira") appears twice - because this order has both billing and shipping details

        // try app.verifyChildElementOnParentCell(parent: "single-product-cell", child: "Mira")
        //this shouldn't work! "single-product-cell" doesn't include the text "Mira"
        app.assertElement(matching: "summary-table-view-cell", existsOnCellWithIdentifier: "\(order.billing.first_name) \(order.billing.last_name)")
        //(mainCell: "summary-table-view-cell", elementToFind: "\(order.billing.first_name) \(order.billing.last_name)")
        //  "\(billing.first_name) + \(billing.last_name)"  "Mira Workman"

        app.assertTextVisibilityCount(textToFind: order.total, expectedCount: 1)
        XCTAssertTrue(app.staticTexts[order.line_items[0].name].isFullyVisibleOnScreen(), "First product name is not visible on screen!")
        //Black Coral shades is first in the mocks, that's what we're referencing, even though Malaya shades appear first on the screen.

        return self
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
