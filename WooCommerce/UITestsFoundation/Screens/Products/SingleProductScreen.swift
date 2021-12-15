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

    public func verifyProductOnSingleProductScreen(name: String, status: String, price: String) throws -> SingleProductScreen {
        var displayedStatus = ""

        switch status {
            case "instock":
                displayedStatus = "in stock"
            case "onbackorder":
                displayedStatus = "on back order"
            case "outofstock":
                displayedStatus = "out of stock"
            default:
                fatalError("Status \(status) is not defined! ")
        }

        var predicate = NSPredicate(format: "label CONTAINS[c] %@", displayedStatus)
        var elementQuery = app.staticTexts.containing(predicate)
        XCTAssertTrue(elementQuery.count == 1, "Stock status does not exist!")

        predicate = NSPredicate(format: "label CONTAINS[c] %@", price)
        elementQuery = app.staticTexts.containing(predicate)
        XCTAssertTrue(elementQuery.count == 1, "Price does not exist!")
        XCTAssert(app.textViews[name].isFullyVisibleOnScreen(), "Product name does not exist!")

        return try SingleProductScreen()
    }
}
