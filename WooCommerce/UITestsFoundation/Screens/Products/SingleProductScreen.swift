import ScreenObject
import XCTest
import XCUITestHelpers

public final class SingleProductScreen: ScreenObject {

    static var isVisible: Bool {
        guard let screen = try? SingleProductScreen() else { return false }
        return screen.isLoaded && screen.expectedElement.isHittable
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ {$0.buttons["edit-product-more-options-button"]} ],
            app: app
        )
    }

    @discardableResult
    public func goBackToProductList() throws -> ProductsScreen {
        navBackButton.tap()
        return try ProductsScreen()
    }

    @discardableResult
    public func verifyProductOnSingleProductScreen(product: ProductData) throws -> Self {
        app.assertTextVisibilityCount(text: product.stock_status)
        app.assertTextVisibilityCount(text: product.regular_price)
        XCTAssertTrue(app.textViews[product.name].isFullyVisibleOnScreen(), "Product name is not visible on screen!")

        return self
    }
}
