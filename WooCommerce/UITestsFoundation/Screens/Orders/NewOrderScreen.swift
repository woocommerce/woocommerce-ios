import ScreenObject
import XCTest

public final class NewOrderScreen: ScreenObject {

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-create-button"]
    }

    private let orderStatusEditButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-status-section-edit-button"]
    }

    private var createButton: XCUIElement { createButtonGetter(app) }

    /// Edit button in the Order Status section.
    ///
    private var orderStatusEditButton: XCUIElement { orderStatusEditButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ createButtonGetter ],
            app: app
        )
    }

    /// Creates a remote order with all of the entered order data.
    /// - Returns: Single Order Detail screen object.
    @discardableResult
    public func createOrder() throws -> SingleOrderScreen {
        createButton.tap()
        return try SingleOrderScreen()
    }

    /// Opens the Order Status screen (to set a new order status).
    /// - Returns: Order Status screen object.
    @discardableResult
    public func openOrderStatusScreen() throws -> OrderStatusScreen {
        orderStatusEditButton.tap()
        return try OrderStatusScreen()
    }
}
