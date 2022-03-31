import ScreenObject
import XCTest

public final class NewOrderScreen: ScreenObject {

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-create-button"]
    }

    private var createButton: XCUIElement { createButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ createButtonGetter ],
            app: app
        )
    }

    @discardableResult
    public func createOrder() throws -> SingleOrderScreen {
        createButton.tap()
        return try SingleOrderScreen()
    }
}
