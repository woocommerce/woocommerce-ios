import ScreenObject
import XCTest

public final class AddProductScreen: ScreenObject {

    private let searchBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.searchFields["product-selector-search-bar"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ searchBarGetter ],
            app: app
        )
    }

    /// Selects a product from the list.
    /// - Returns: New Order screen object.
    @discardableResult
    public func selectProduct(byName name: String) throws -> NewOrderScreen {
        app.buttons.staticTexts[name].tap()
        return try NewOrderScreen()
    }
}
