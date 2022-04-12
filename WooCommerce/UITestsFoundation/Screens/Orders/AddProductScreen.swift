import ScreenObject
import XCTest

public final class AddProductScreen: ScreenObject {

    private let searchBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.searchFields["new-order-add-product-search-bar"]
    }


    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ searchBarGetter ],
            app: app
        )
    }
}
