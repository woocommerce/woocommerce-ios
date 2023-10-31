import ScreenObject
import XCTest

public final class AddCustomAmountScreen: ScreenObject {
    private let addCustomAmountButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-add-custom-amount-view-add-custom-amount-button"]
    }

    private var addCustomAmountButton: XCUIElement { addCustomAmountButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ addCustomAmountButtonGetter ],
            app: app
        )
    }

    /// Enters a custom amount by tapping a button on the numeric keypad.
    /// This is done instead of entering text because the text field for custom amount
    /// is custom, and gets no keyboard focus when tapped.
    /// - Returns: Add Custom Amount screen object.
    @discardableResult
    public func enterCustomAmount(amount: String) throws -> Self {
        app.keyboards.keys[amount].firstMatch.tap()
        return self
    }

    /// Confirms entered custom amount.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func addCustomAmountTap() throws -> UnifiedOrderScreen {
        addCustomAmountButton.tap()
        return try UnifiedOrderScreen()
    }
}
