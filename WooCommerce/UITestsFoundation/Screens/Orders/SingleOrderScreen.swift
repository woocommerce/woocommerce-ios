import ScreenObject
import XCTest

public final class SingleOrderScreen: ScreenObject {

    let tabBar: TabNavComponent

    private let editOrderButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-details-edit-button"]
    }

    private let summaryCellTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["summary-table-view-cell-title-label"]
    }

    private let summaryCellPaymentStatusGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["summary-table-view-cell-payment-status-label"]
    }

    private let collectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-details-collect-payment-button"]
    }

    private var editOrderButton: XCUIElement { editOrderButtonGetter(app) }

    private var collectPaymentButton: XCUIElement { collectPaymentButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent(app: app)

        try super.init(
            expectedElementGetters: [ summaryCellTitleGetter, summaryCellPaymentStatusGetter ],
            app: app
        )
    }

    @discardableResult
    public func verifySingleOrderScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    @discardableResult
    public func verifySingleOrder(order: OrderData) throws -> Self {
        // Check that navigation bar contains order number
        let navigationBarTitles = app.navigationBars.map { $0.staticTexts.element.label }
        let expectedTitle = "#\(order.number)"
        XCTAssertTrue(navigationBarTitles.contains(where: { $0.contains(expectedTitle) }), "No navigation bar found with title \(expectedTitle)")

        let orderDetailTableView = app.tables["order-details-table-view"]
        orderDetailTableView.assertTextVisibilityCount(textToFind: order.status, expectedCount: 1)
        orderDetailTableView.assertTextVisibilityCount(textToFind: order.total, expectedCount: 1)

        // Expects 2 instances of first_name - one in Summary and one in Shipping details
        orderDetailTableView.assertTextVisibilityCount(textToFind: order.billing.first_name, expectedCount: 2)
        orderDetailTableView.assertElement(matching: "summary-table-view-cell",
                                           existsOnCellWithIdentifier: "\(order.billing.first_name) \(order.billing.last_name)")

        for product in order.line_items {
            XCTAssertTrue(orderDetailTableView.staticTexts[product.name].isFullyVisibleOnScreen(), "'\(product.name)' is missing!")
        }

        return self
    }

    public func tapCollectPaymentButton() throws -> PaymentMethodsScreen {
        let orderDetailTableView = app.tables["order-details-table-view"]
        while !collectPaymentButton.isFullyVisibleOnScreen() {
            orderDetailTableView.swipeUp()
        }
        collectPaymentButton.tap()
        return try PaymentMethodsScreen()
    }

    public func goBackToOrdersScreen() throws -> OrdersScreen {
        // Only needed for iPhone because iPad shows both Orders and Single Order screens on the same view
        if XCUIDevice.isPhone {
            pop()
        }
        return try OrdersScreen()
    }

    public func tapEditOrderButton() throws -> UnifiedOrderScreen {
        editOrderButton.tap()
        return try UnifiedOrderScreen(flow: .editing)
    }
}
