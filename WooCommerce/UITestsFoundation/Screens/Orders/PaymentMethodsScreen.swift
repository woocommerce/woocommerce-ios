import ScreenObject
import XCTest

public final class PaymentMethodsScreen: ScreenObject {

    private let cardMethodButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-card-row"]
    }

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
}
