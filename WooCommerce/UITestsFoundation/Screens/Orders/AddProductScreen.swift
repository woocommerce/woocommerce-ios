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

    /// Taps a product from the list.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func tapProduct(byName name: String) throws -> UnifiedOrderScreen {
        app.buttons.staticTexts[name].firstMatch.tap()
        tapDoneButton()
        return try UnifiedOrderScreen()
    }

    /// Taps multiple products from the list.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func tapMultipleProducts(numberOfProductsToAdd: Int) throws -> UnifiedOrderScreen {
        for product in 0..<numberOfProductsToAdd {
            let products = app.buttons.matching(identifier: "product-item")
            products.element(boundBy: product).tap()
        }
        tapDoneButton()
        return try UnifiedOrderScreen()
    }

    public func tapDoneButton() {
        if doneButton.exists {
            doneButton.tap()
        }
    }
}
