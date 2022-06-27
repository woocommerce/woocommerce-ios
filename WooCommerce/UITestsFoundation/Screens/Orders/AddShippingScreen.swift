import ScreenObject
import XCTest

public final class AddShippingScreen: ScreenObject {

    private let shippingAmountGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["add-shipping-amount-field"]
    }

    private let shippingNameGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["add-shipping-name-field"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-shipping-done-button"]
    }

    private var shippingAmountField: XCUIElement { shippingAmountGetter(app) }

    private var shippingNameField: XCUIElement { shippingNameGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ shippingAmountGetter ],
            app: app
        )
    }

    /// Enters a shipping amount.
    /// - Returns: Add Shipping screen object.
    @discardableResult
    public func enterShippingAmount(_ amount: String) throws -> Self {
        shippingAmountField.tap()
        shippingAmountField.typeText(amount)
        return self
    }

    /// Enters a shipping name.
    /// - Returns: Add Shipping screen object.
    @discardableResult
    public func enterShippingName(_ name: String) throws -> Self {
        shippingNameField.tap()
        shippingNameField.typeText(name)
        return self
    }

    /// Confirms entered shipping details and closes Add Shipping screen.
    /// - Returns: New Order screen object.
    @discardableResult
    public func confirmShippingDetails() throws -> NewOrderScreen {
        doneButton.tap()
        return try NewOrderScreen()
    }
}
