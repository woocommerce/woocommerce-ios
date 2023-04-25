import ScreenObject
import XCTest

public final class PaymentsScreen: ScreenObject {
    private let collectPaymentButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["collect-payment"]
    }

    private let cardReaderManualsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["card-reader-manuals"]
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

    @discardableResult
    public func verifyPaymentsScreenLoaded() throws -> PaymentsScreen {
        XCTAssertTrue(isLoaded)
        return self
    }

    public func verifyIPPDocumentationLoadedInWebView() throws {
        XCTAssertTrue(IPPDocumentationHeaderText.waitForExistence(timeout: 10), "IPP Documentation not displayed on WebView!")
    }
}
