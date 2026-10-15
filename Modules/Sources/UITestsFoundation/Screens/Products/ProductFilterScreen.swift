import ScreenObject
import XCTest

public final class ProductFilterScreen: ScreenObject {

    private let stockStatusButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["product-filter-stock-status-cell"]
    }

    private let showProductsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["filter-apply-button"]
    }

    private var stockStatusButton: XCUIElement { stockStatusButtonGetter(app) }
    private var showProductsButton: XCUIElement { showProductsButtonGetter(app) }


    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ stockStatusButtonGetter, showProductsButtonGetter ],
            app: app
        )
    }

    public func setStockStatusFilterAs(_ filter: String) throws -> ProductsScreen {
        stockStatusButton.tap()
        app.cells["product-stock-status-\(filter)"].tap()
        showProductsButton.tap()

        return try ProductsScreen()
    }
}
