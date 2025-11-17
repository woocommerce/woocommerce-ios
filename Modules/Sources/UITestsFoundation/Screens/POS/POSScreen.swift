import ScreenObject
import XCTest

public final class POSScreen: ScreenObject {

    private let cartViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["pos-cart-view"]
    }

    private let firstProductButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["pos-product-card-1"]
    }

    private var firstProductButton: XCUIElement { firstProductButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [cartViewGetter],
            app: app
        )
    }
    
    @discardableResult
    public func tapAddProduct() -> Self {
        guard firstProductButton.waitForExistence(timeout: 3) else {
            return self
        }

        firstProductButton.tap()
        return self
    }
}
