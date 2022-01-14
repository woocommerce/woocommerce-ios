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
        app.assertTextVisibilityCount(textToFind: order.total, expectedCount: 1)

        // Adding # to textToFind to eliminate the case where number matches product price
        // Expects 2 instances of order.number - one in Header and one in Summary
        app.assertTextVisibilityCount(textToFind: "#\(order.number)", expectedCount: 2)

        // Temporary excluding until GH Issue is fixed: https://github.com/woocommerce/woocommerce-ios/issues/5894
        let issueFixed = false
        if issueFixed == true {
            // Expects 2 instances of first_name - one in Summary and one in Shipping details
            app.assertTextVisibilityCount(textToFind: order.billing.first_name, expectedCount: 2)
        }

        app.assertElement(matching: "summary-table-view-cell", existsOnCellWithIdentifier: "\(order.billing.first_name) \(order.billing.last_name)")

        // Loops through all products on the order
        for i in 0...order.line_items.count - 1 {
            XCTAssertTrue(app.staticTexts[order.line_items[i].name].isFullyVisibleOnScreen(), "'\(order.line_items[i].name)' is missing!")
        }

        return self
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
