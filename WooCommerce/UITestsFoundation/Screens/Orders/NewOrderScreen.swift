import ScreenObject
import XCTest

public final class NewOrderScreen: ScreenObject {

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-create-button"]
    }

    private let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-cancel-button"]
    }

    private var createButton: XCUIElement { createButtonGetter(app) }

    private var cancelButton: XCUIElement { cancelButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                createButtonGetter,
                cancelButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func createOrder() throws -> SingleOrderScreen {
        createButton.tap()
        return try SingleOrderScreen()
    }
    
    @discardableResult
    public func cancelOrderCreation() throws -> OrdersScreen {
        cancelButton.tap()
        return try OrdersScreen()
    }
}
