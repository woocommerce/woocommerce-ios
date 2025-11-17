import ScreenObject
import XCTest

public final class POSScreen: ScreenObject {

    private let cartViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["pos-cart-view"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [cartViewGetter],
            app: app
        )
    }

    @discardableResult
    public func tapAddProduct(productID: Int) -> Self {
        let productButton = app.buttons["pos-product-card-\(productID)"]

        guard productButton.waitForExistence(timeout: 1) else {
            return self
        }
        productButton.tap()

        return self
    }
}
