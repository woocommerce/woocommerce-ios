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

    public func verifyProductOnSingleProductScreen(name: String, price: String, status: String) throws -> Self {
        XCTAssertTrue(try app.getTextVisibilityCount(text: status) == 1, "Stock status does not exist!")
        XCTAssertTrue(try app.getTextVisibilityCount(text: price) == 1, "Price does not exist!")
        XCTAssertTrue(app.textViews[name].isFullyVisibleOnScreen(), "Product name does not exist!")

        return self
    }
}
