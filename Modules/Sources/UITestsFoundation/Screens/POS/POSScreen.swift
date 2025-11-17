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

    @discardableResult
    public func tapCheckout() -> Self {
        let checkoutButton = app.buttons["pos-checkout-button"]

        guard checkoutButton.waitForExistence(timeout: 3) else {
            return self
        }

        checkoutButton.tap()
        return self
    }

    @discardableResult
    public func waitForTotalsLoaded() -> Self {
        // Wait for the actual totals to load (not shimmer/ghost state)
        // This waits for orderState to be .loaded and payment to start
        let totalField = app.otherElements["pos-total-field"]

        guard totalField.waitForExistence(timeout: 5) else {
            return self
        }

        return self
    }
}
