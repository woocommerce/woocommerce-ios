import ScreenObject
import XCTest

@MainActor
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
        let chipperManualPredicate = NSPredicate(format: "label CONTAINS[c] %@", "ChipperTM 2X BT")
        let chipperManualContent = app.webViews.descendants(matching: .any).matching(chipperManualPredicate).firstMatch

        XCTAssertTrue(
            chipperManualContent.waitForExistence(timeout: 30),
            "Chipper manual content not detected in web view!"
        )
        return self
    }
}
