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
}
