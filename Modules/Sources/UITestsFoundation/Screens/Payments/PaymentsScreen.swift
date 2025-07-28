import ScreenObject
import XCTest

public final class PaymentsScreen: ScreenObject {
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

    public func clickLearnMoreIPPLink() throws -> Self {
        try XCTSkipIf(
            UIDevice.current.userInterfaceIdiom == .phone,
            """
            Skipping on the iPhone.
            Calling tap() on a link within attributed text no longer works in UI tests on Xcode 16.
            Using click() instead, which is only supported on iPad.
            """
        )

        learnMoreButton.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).click()
        return self
    }

    @discardableResult
    public func verifyPaymentsScreenLoaded() throws -> PaymentsScreen {
        XCTAssertTrue(paymentsNavigationBar.waitForExistence(timeout: 8))
        return self
    }

    public func verifyIPPDocumentationLoadedInWebView() throws {
        XCTAssertTrue(IPPDocumentationHeaderText.waitForExistence(timeout: 30), "IPP Documentation not displayed on WebView!")
    }
}
