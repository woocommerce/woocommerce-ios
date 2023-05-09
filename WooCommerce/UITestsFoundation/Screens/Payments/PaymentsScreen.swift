import ScreenObject
import XCTest

public final class PaymentsScreen: ScreenObject {
    private let collectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["collect-payment"]
    }

    private let cardReaderManualsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["card-reader-manuals"]
    }

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["next-button"]
    }

    private let takePaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["take-payment-button"]
    }

    private let cashPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["payment-methods-view-cash-row"]
    }

    private let markAsPaidButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Mark as Paid"]
    }

    private let learnMoreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Learn more about In‑Person Payments"]
    }

    private let IPPDocumentationHeaderTextGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Getting started with In-Person Payments with WooCommerce Payments"]
    }

    private var collectPaymentButton: XCUIElement { collectPaymentButtonGetter(app) }
    private var cardReaderManualsButton: XCUIElement { cardReaderManualsButtonGetter(app) }
    private var learnMoreButton: XCUIElement { learnMoreButtonGetter(app) }
    private var nextButton: XCUIElement { nextButtonGetter(app) }
    private var takePaymentButton: XCUIElement { takePaymentButtonGetter(app) }
    private var cashPaymentButton: XCUIElement { cashPaymentButtonGetter(app) }
    private var markAsPaidButton: XCUIElement { markAsPaidButtonGetter(app) }
    private var IPPDocumentationHeaderText: XCUIElement { IPPDocumentationHeaderTextGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ collectPaymentButtonGetter, cardReaderManualsButtonGetter ],
            app: app
        )
    }

    @discardableResult
    public func tapCardReaderManuals() throws -> CardReaderManualsScreen {
        cardReaderManualsButton.tap()
        return try CardReaderManualsScreen()
    }

    public func tapLearnMoreIPPLink() throws -> Self {
        learnMoreButton.tap()
        return self
    }

    public func tapCollectPayment() throws -> Self {
        collectPaymentButton.tap()
        return self
    }

    public func enterPaymentAmount(_ amount: String) throws -> Self {
        app.enterText(text: amount)
        nextButton.tap()
        return self
    }

    public func takeCashPayment() throws -> Self {
        takePaymentButton.waitAndTap()
        cashPaymentButton.waitAndTap()

        markAsPaidButton.tap()
        return self
    }

    @discardableResult
    public func verifyOrderCompletedToastDisplayed() throws -> Self {
        let orderCompletedToast = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Order completed'")).firstMatch
        XCTAssertTrue(orderCompletedToast.exists)

        return self
    }

    @discardableResult
    public func verifyPaymentsScreenLoaded() throws -> PaymentsScreen {
        collectPaymentButton.waitForExistence(timeout: 15)
        XCTAssertTrue(isLoaded)
        return self
    }

    public func verifyIPPDocumentationLoadedInWebView() throws {
        XCTAssertTrue(IPPDocumentationHeaderText.waitForExistence(timeout: 10), "IPP Documentation not displayed on WebView!")
    }
}
