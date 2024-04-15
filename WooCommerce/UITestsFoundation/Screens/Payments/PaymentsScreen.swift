import ScreenObject
import XCTest

public final class PaymentsScreen: ScreenObject {
    private let collectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["collect-payment"]
    }

    private let cardReaderManualsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["card-reader-manuals"]
    }

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["next-button"]
    }

    private let cashPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-cash-row"]
    }

    private let markAsPaidButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Mark Order as Complete"]
    }

    private let learnMoreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["Learn more about In‑Person Payments"].firstMatch
    }

    private let IPPDocumentationHeaderTextGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Getting started with In-Person Payments with WooPayments"]
    }

    private let paymentsNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Payments"]
    }

    private let addCustomAmountGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["simple-payments-migration-add-custom-amount"]
    }

    private let confirmCustomAmountGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-add-custom-amount-view-add-custom-amount-button"]
    }

    private let orderFormCollectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-form-collect-payment"]
    }

    private var collectPaymentButton: XCUIElement { collectPaymentButtonGetter(app) }
    private var cardReaderManualsButton: XCUIElement { cardReaderManualsButtonGetter(app) }
    private var learnMoreButton: XCUIElement { learnMoreButtonGetter(app) }
    private var nextButton: XCUIElement { nextButtonGetter(app) }
    private var paymentsNavigationBar: XCUIElement { paymentsNavigationBarGetter(app) }
    private var cashPaymentButton: XCUIElement { cashPaymentButtonGetter(app) }
    private var markAsPaidButton: XCUIElement { markAsPaidButtonGetter(app) }
    private var IPPDocumentationHeaderText: XCUIElement { IPPDocumentationHeaderTextGetter(app) }
    private var addCustomAmountButton: XCUIElement { addCustomAmountGetter(app) }
    private var confirmCustomAmountButton: XCUIElement { confirmCustomAmountGetter(app) }
    private var orderFormCollectPaymentButton: XCUIElement { orderFormCollectPaymentButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                paymentsNavigationBarGetter,
                collectPaymentButtonGetter,
                cardReaderManualsButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func tapCardReaderManuals() throws -> CardReaderManualsScreen {
        cardReaderManualsButton.tap()
        return try CardReaderManualsScreen()
    }

    public func tapLearnMoreIPPLink() throws -> Self {
        learnMoreButton.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
        return self
    }

    public func tapCollectPayment() throws -> Self {
        collectPaymentButton.tap()
        return self
    }

    /// Enters a custom amount by tapping a button on the numeric keypad.
    /// This is done instead of entering text because the text field for custom amount
    /// is custom with opacity 0, and gets no keyboard focus when tapped.
    public func enterPaymentAmount(_ amount: String) throws -> Self {
        addCustomAmountButton.waitAndTap()
        app.keyboards.keys[amount].firstMatch.tap()
        confirmCustomAmountButton.waitAndTap()
        return self
    }

    public func takeCashPayment() throws -> Self {
        orderFormCollectPaymentButton.waitAndTap()
        cashPaymentButton.waitAndTap()
        markAsPaidButton.waitAndTap()
        return self
    }

    @discardableResult
    public func verifyOrderCompletedToastDisplayed() throws -> Self {
        let orderCompletedToast = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Order completed'")).firstMatch
        XCTAssertTrue(orderCompletedToast.waitForExistence(timeout: 8))

        return self
    }

    @discardableResult
    public func verifyPaymentsScreenLoaded() throws -> PaymentsScreen {
        XCTAssertTrue(collectPaymentButton.waitForExistence(timeout: 8))
        return self
    }

    public func verifyIPPDocumentationLoadedInWebView() throws {
        XCTAssertTrue(IPPDocumentationHeaderText.waitForExistence(timeout: 30), "IPP Documentation not displayed on WebView!")
    }
}
