import ScreenObject
import XCTest

public final class SingleOrderScreen: ScreenObject {

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
        let orderTotalPredicate = NSPredicate(format: "label CONTAINS %@", order.total)

        // Check that navigation bar contains order number
        let orderNumberPredicate = NSPredicate(format: "identifier CONTAINS %@ OR label CONTAINS %@", order.number, order.number)
        XCTAssertTrue(app.navigationBars.matching(orderNumberPredicate).firstMatch.exists, "No navigation bar found for order \(order.number)")

        // Check order status and total
        let orderDetailTableView = app.tables["order-details-table-view"]
        XCTAssertTrue(orderDetailTableView.buttons["order-status-\(order.status)"].exists)
        XCTAssertTrue(app.otherElements.containing(orderTotalPredicate).element.exists)

        // Check name on order summary
        orderDetailTableView.assertStaticText(withLabel: "\(order.billing.first_name) \(order.billing.last_name)",
                                              existsOnCellWithIdentifier: "summary-table-view-cell")

        // Check product(s) on order
        for product in order.line_items {
            XCTAssertTrue(orderDetailTableView.staticTexts[product.name].isFullyVisibleOnScreen(), "'\(product.name)' is missing!")
        }

        return self
    }

    public func tapCollectPaymentButton() throws -> PaymentMethodsScreen {
        let orderDetailTableView = app.tables["order-details-table-view"]

        while !collectPaymentButton.isFullyVisibleOnScreen() {
            // Manually do a shorter swipe up here instead of using `.swipeUp` because on smaller screen,
            // the swipe passes the Collect Payment Button.
            let startCoord = orderDetailTableView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            let endCoord = orderDetailTableView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            startCoord.press(forDuration: 0.01, thenDragTo: endCoord)
        }

        collectPaymentButton.tap()

        return try PaymentMethodsScreen()
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        let orderDetailTableView = app.tables["order-details-table-view"]

        guard orderDetailTableView.horizontalSizeClass == .compact else {
            return try OrdersScreen()
        }

        pop()
        return try OrdersScreen()
    }

    public func tapEditOrderButton() throws -> UnifiedOrderScreen {
        editOrderButton.tap()
        return try UnifiedOrderScreen(flow: .editing)
    }
}
