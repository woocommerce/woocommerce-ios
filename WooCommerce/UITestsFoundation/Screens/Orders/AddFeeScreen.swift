import ScreenObject
import XCTest

public final class AddFeeScreen: ScreenObject {

    private let feeFixedAmountGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["add-fee-fixed-amount-field"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-fee-done-button"]
    }

    private var feeFixedAmountField: XCUIElement { feeFixedAmountGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ feeFixedAmountGetter ],
            app: app
        )
    }

    /// Enters a fixed fee amount.
    /// - Returns: Add Fee screen object.
    @discardableResult
    public func enterFixedFee(amount: String) throws -> Self {
        feeFixedAmountField.tap()
        feeFixedAmountField.typeText(amount)
        return self
    }

    /// Confirms entered fee and closes Add Fee screen.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func confirmFee() throws -> UnifiedOrderScreen {
        doneButton.tap()
        return try UnifiedOrderScreen()
    }
}
