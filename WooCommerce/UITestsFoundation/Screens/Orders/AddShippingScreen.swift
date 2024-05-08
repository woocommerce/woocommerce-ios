import ScreenObject
import XCTest

public final class AddShippingScreen: ScreenObject {

    private let shippingNameGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["add-shipping-name-field"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-shipping-done-button"]
    }

    private var shippingNameField: XCUIElement { shippingNameGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ doneButtonGetter ],
            app: app
        )
    }

    /// Enters a shipping amount by tapping a button on the numeric keypad.
    /// This is done instead of entering text because the text field for shipping amount
    /// is custom with opacity 0, and gets no keyboard focus when tapped.
    /// - Returns: Add Shipping screen object.
    @discardableResult
    public func enterShippingAmount(_ amount: String) throws -> Self {
        amount.forEach { character in
            app.keyboards.keys[String(character)].firstMatch.tap()
        }
        return self
    }

    /// Enters a shipping name.
    /// - Returns: Add Shipping screen object.
    @discardableResult
    public func enterShippingName(_ name: String) throws -> Self {
        shippingNameField.tap()
        shippingNameField.tap() // For some reason this field doesn't get keyboard focus until the second tap, in the UI test only.
        shippingNameField.typeText(name)
        return self
    }

    /// Confirms entered shipping details and closes Add Shipping screen.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func confirmShippingDetails() throws -> UnifiedOrderScreen {
        doneButton.tap()
        return try UnifiedOrderScreen()
    }
}
