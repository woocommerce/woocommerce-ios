import ScreenObject
import XCTest

public final class OrderStatusScreen: ScreenObject {

    private let orderStatusTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["order-status-list"]
    }

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
    public func selectOrderStatus(atIndex index: Int) throws -> UnifiedOrderScreen {
        orderStatusTable.cells.element(boundBy: index).tap()
        return try UnifiedOrderScreen()
    }
}
