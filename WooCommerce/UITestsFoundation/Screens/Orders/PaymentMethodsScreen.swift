import ScreenObject
import XCTest

public final class PaymentMethodsScreen: ScreenObject {

    private let cardMethodButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-card-row"]
    }

    private let dismissButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-cancel-button"]
    }

    /// Button to dismiss a the modal
    ///
    private var dismissButton: XCUIElement { dismissButtonGetter(app) }

    /// Button to dismiss a the modal
    ///
    private var cardMethodButton: XCUIElement { cardMethodButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["payment-methods-header-label"]} ],
            app: app
        )
    }

    @discardableResult
    public func selectCardPresentPayment() throws -> CardPresentPaymentsModalScreen {
        cardMethodButton.tap()
        return try CardPresentPaymentsModalScreen()
    }

    @discardableResult
    public func goBackToOrderScreen() throws -> SingleOrderScreen {
        dismissButton.tap()
        return try SingleOrderScreen()
    }
}
