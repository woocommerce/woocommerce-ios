import ScreenObject
import XCTest

public final class OrderStatusScreen: ScreenObject {

    private let applyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-status-list-apply-button"]
    }

    private let orderStatusTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["order-status-list"]
    }

    private var applyButton: XCUIElement { applyButtonGetter(app) }

    /// Table with list of order statuses.
    ///
    private var orderStatusTable: XCUIElement { orderStatusTableGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ orderStatusTableGetter ],
            app: app
        )
    }

    /// Selects a new order status from the list.
    /// - Returns: Order Status screen object (self).
    @discardableResult
    public func selectOrderStatus(atIndex index: Int) throws -> Self {
        orderStatusTable.cells.element(boundBy: index).tap()
        return self
    }

    /// Updates the order with the selected order status.
    /// - Returns: New Order screen object.
    @discardableResult
    public func confirmSelectedOrderStatus() throws -> NewOrderScreen {
        applyButton.tap()
        return try NewOrderScreen()
    }
}
