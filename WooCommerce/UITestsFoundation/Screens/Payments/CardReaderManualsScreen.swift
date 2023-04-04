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
    public func verifyChipperManualLoadedOnWebView() throws -> Self {
        let chipperManualPredicate = NSPredicate(format: "label CONTAINS[c] %@", "ChipperTM 2X BT")
        let chipperManualText = app.webViews.textViews.containing(chipperManualPredicate).element

        XCTAssert(chipperManualText.waitForExistence(timeout: 20), "Chipper manual not displayed on WebView!")
        return self
    }
}
