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
    public func verifyProduct(product: ProductData) throws -> Self {
        app.assertTextVisibilityCount(textToFind: product.stock_status, expectedCount: 1)
        app.assertTextVisibilityCount(textToFind: product.regular_price, expectedCount: 1)
        XCTAssertTrue(app.textViews[product.name].isFullyVisibleOnScreen(), "Product name is not visible on screen!")

        return self
    }

    public func addProductTitle(productTitle: String) throws -> Self {
        app.cells["product-title"].enterText(text: productTitle)
        return self
    }

    public func publishProduct() throws -> Self {
        app.buttons["publish-product-button"].tap()
        return self
    }

    public func verifyPublishedProductScreenLoaded(productType: String, productName: String) {
        let priceLabel = NSPredicate(format: "label == 'Price'")
        let addVariationLabel = NSPredicate(format: "label == 'Add variations'")

        // common fields on a published product screen
        XCTAssertTrue(app.buttons["save-product-button"].exists)
        XCTAssertTrue(app.staticTexts["TIP"].exists)
        XCTAssertTrue(app.textViews[productName].exists)

        // different product types displays different fields on the published product screen
        // this is to validate that the correct screens are displayed
        switch productType {
        case "physical", "virtual":
            XCTAssertTrue(app.staticTexts.containing(priceLabel).firstMatch.exists)
        case "variable":
            XCTAssertTrue(app.staticTexts.containing(addVariationLabel).firstMatch.exists)
        default:
            fatalError("Product Type \(productType) doesn't exist!")
        }
    }

    public func verifyProductTypeScreenLoaded(productType: String) throws -> Self {
        let addPriceLabel = NSPredicate(format: "label == 'Add Price'")
        let inventoryLabel = NSPredicate(format: "label == 'Inventory'")
        let addVariationLabel = NSPredicate(format: "label == 'Add variations'")
        let productTypeLabel = NSPredicate(format: "label ==[c] '\(productType)'")

        // the common fields on add product screen
        XCTAssertTrue(app.cells["product-review-cell"].exists)
        XCTAssertTrue(app.staticTexts.containing(productTypeLabel).firstMatch.exists)

        // different product types displays different fields on add product screen
        // this is to validate that the correct screens are displayed
        switch productType {
        case "physical", "virtual":
            XCTAssertTrue(app.staticTexts.containing(addPriceLabel).firstMatch.exists)
            XCTAssertTrue(app.staticTexts.containing(inventoryLabel).firstMatch.exists)
        case "variable":
            XCTAssertTrue(app.staticTexts.containing(addVariationLabel).firstMatch.exists)
            XCTAssertTrue(app.staticTexts.containing(inventoryLabel).firstMatch.exists)
        default:
            fatalError("Product Type \(productType) doesn't exist!")
        }
        return self
    }
}
