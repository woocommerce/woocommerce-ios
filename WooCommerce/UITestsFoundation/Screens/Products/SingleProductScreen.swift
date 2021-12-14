import ScreenObject
import XCTest

public final class SingleProductScreen: ScreenObject {

    static var isVisible: Bool {
        guard let screen = try? SingleProductScreen() else { return false }
        return screen.isLoaded && screen.expectedElement.isHittable
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
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

    public func verifyProductNameOnSingleProductScreen(name: String) {
        XCTAssert(app.textViews[name].exists, "Product name does not exist!")
    }
}
