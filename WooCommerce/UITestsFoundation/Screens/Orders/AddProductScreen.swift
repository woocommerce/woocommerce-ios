import ScreenObject
import XCTest

public final class AddProductScreen: ScreenObject {

    private let searchBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.searchFields["product-selector-search-bar"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["product-multiple-selection-done-button"]
    }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ searchBarGetter, doneButtonGetter ],
            app: app
        )
    }

    /// Selects a product from the list.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func selectProduct(byName name: String) throws -> UnifiedOrderScreen {
        app.buttons.staticTexts[name].tap()
        return try UnifiedOrderScreen()
    }

    /// Selects multiple products from the list.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func selectMultipleProducts(byName names: [String]) throws -> UnifiedOrderScreen {
        app.buttons.staticTexts[names[0]].tap()
        // TODO: Add further scenarios in next iterations: https://github.com/woocommerce/woocommerce-ios/issues/8997
        if doneButton.exists {
            doneButton.tap()
        }
        return try UnifiedOrderScreen()
    }
}
