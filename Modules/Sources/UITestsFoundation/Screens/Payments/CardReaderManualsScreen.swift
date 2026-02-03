import ScreenObject
import XCTest

public final class CardReaderManualsScreen: ScreenObject {
    private let chipperManualButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["BBPOS Chipper 2X BT"]
    }

    private let stripeManualButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Stripe Reader M2"]
    }

    private var chipperManualButton: XCUIElement { chipperManualButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                chipperManualButtonGetter,
                stripeManualButtonGetter
            ],
            app: app
        )
    }

    static var isVisible: Bool {
        (try? CardReaderManualsScreen().isLoaded) ?? false
    }

    @discardableResult
    public func tapChipperManual() throws -> Self {
        chipperManualButton.tap()
        return self
    }

    @discardableResult
    public func verifyChipperManualLoadedInWebView() throws -> Self {
        let webViews = app.webViews
        let chipperManualPredicate = NSPredicate(format: "label CONTAINS[c] %@", "ChipperTM 2X BT")

        let chipperManualStaticText = webViews.staticTexts.containing(chipperManualPredicate).element
        let chipperManualTextView = webViews.textViews.containing(chipperManualPredicate).element

        let pdfRenderedAsStaticText = chipperManualStaticText.waitForExistence(timeout: 10)
        let pdfRenderedInTextView = chipperManualTextView.waitForExistence(timeout: 10)

        XCTAssertTrue(
            pdfRenderedInTextView ||
            pdfRenderedAsStaticText,
            "Chipper manual content not detected in web view!"
        )
        return self
    }
}
