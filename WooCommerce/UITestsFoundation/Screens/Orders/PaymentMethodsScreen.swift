import ScreenObject
import XCTest

public final class PaymentMethodsScreen: ScreenObject {

    private let cardMethodButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-card-row"]
    }

    private let dismissButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-cancel-button"]
    }

    /// Button to dismiss the the modal
    ///
    private var dismissButton: XCUIElement { dismissButtonGetter(app) }

    /// Button to select the card payment method
    ///
    private var cardMethodButton: XCUIElement { cardMethodButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["payment-methods-header-label"]} ],
            app: app
        )
    }

    @discardableResult
    public func tapCardPresentPayment() throws -> CardPresentPaymentsModalScreen {
        cardMethodButton.tap()
        return try CardPresentPaymentsModalScreen()
    }

    @discardableResult
    public func goBackToOrderScreen() throws -> SingleOrderScreen {
        dismissButton.tap()

        let orderDetailTableView = app.tables["order-details-table-view"]
        // On smaller screen, the Summary area might not be visible anymore. We need to bring it back so when returning
        // back from Payment Details, it can be detected.
        orderDetailTableView.swipeDown()

        return try SingleOrderScreen()
    }
}
