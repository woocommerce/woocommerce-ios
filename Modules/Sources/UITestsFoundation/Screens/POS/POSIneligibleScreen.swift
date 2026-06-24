import ScreenObject
import XCTest

// periphery: ignore - used for UI testing
public final class POSIneligibleScreen: ScreenObject {
    private let ineligibleViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.descendants(matching: .any)["pos-ineligible-view"]
    }
    private let titleGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["pos-ineligible-title"]
    }
    private let suggestionGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["pos-ineligible-suggestion"]
    }
    private let retryButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["pos-ineligible-refresh-button"]
    }
    private let dismissButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["pos-ineligible-dismiss-button"]
    }

    private var title: XCUIElement { titleGetter(app) }
    private var suggestion: XCUIElement { suggestionGetter(app) }
    private var retryButton: XCUIElement { retryButtonGetter(app) }
    private var dismissButton: XCUIElement { dismissButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ineligibleViewGetter],
            app: app,
            waitTimeout: 30
        )
    }

    @discardableResult
    public func verifyUnsupportedWooCommerceVersion() -> Self {
        XCTAssertTrue(title.waitForExistence(timeout: 5), "POS ineligible title should be visible.")
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "POS ineligible suggestion should be visible.")
        XCTAssertTrue(suggestion.label.contains("WooCommerce version"), "Expected unsupported WooCommerce version message.")
        XCTAssertTrue(retryButton.waitForExistence(timeout: 5), "Retry button should be visible.")
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 5), "Exit POS button should be visible.")
        return self
    }

    @discardableResult
    public func tapExitPOS() throws -> TabNavComponent {
        XCTAssertTrue(dismissButton.waitForIsHittable(timeout: 5), "Exit POS button should be tappable.")
        dismissButton.tap()
        return try TabNavComponent(app: app)
    }
}
