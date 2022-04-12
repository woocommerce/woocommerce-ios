import ScreenObject
import XCTest

public final class AddProductScreen: ScreenObject {

    private let productListGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["new-order-add-product-list"]
        //add a getter for an item on this screen that is functionally required
    }


    /// List of products
    ///
    private var productList: XCUIElement { productListGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ productListGetter ],
            app: app
        )
    }
}
