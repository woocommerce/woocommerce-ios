import ScreenObject
import XCTest
import XCUITestHelpers

public final class SingleProductScreen: ScreenObject {

    static var isVisible: Bool {
        guard let screen = try? SingleProductScreen() else { return false }
        return screen.isLoaded && screen.expectedElement.isHittable
    }

    private var productFormTable: XCUIElement {
        app.tables["product-form"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ {$0.buttons["edit-product-more-options-button"]} ],
            app: app
        )
    }

    @discardableResult
    public func goBackToProductList() throws -> ProductsScreen {
        let navBackButton = app.navigationBars.element(boundBy: 0).buttons["Products"]
        // If split view is enabled, back button is not shown in the product form navigation bar.
        if navBackButton.exists {
            navBackButton.tap()
        }
        return try ProductsScreen()
    }

    @discardableResult
    public func verifyProduct(product: ProductData) throws -> Self {
        productFormTable.assertTextVisibilityCount(textToFind: product.stock_status, expectedCount: 1)
        productFormTable.assertTextVisibilityCount(textToFind: product.regular_price, expectedCount: 1)
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
        // common fields on a published product screen
        XCTAssertTrue(app.buttons["save-product-button"].waitForExistence(timeout: 10), "Save button is not displayed!")
        XCTAssertTrue(app.staticTexts["TIP"].exists)
        XCTAssertTrue(app.textViews[productName].exists)

        // different product types display different fields on the published product screen
        // this is to validate that the correct screens are displayed
        switch productType {
        case "physical", "virtual":
            XCTAssertTrue(app.staticTexts["Price"].exists)
        case "variable":
            XCTAssertTrue(app.staticTexts["Add variations"].exists)
        case "grouped":
            XCTAssertTrue(app.staticTexts["Grouped products"].exists)
        case "external":
            XCTAssertTrue(app.staticTexts["Add product link"].exists)
        default:
            XCTFail("Product Type \(productType) doesn't exist!")
        }
    }

    public func verifyProductTypeScreenLoaded(productType: String) throws -> Self {
        let productTypeLabel = productType + (productType == "external" ? "/Affiliate" : "")
        let productTypeLabelPredicate = NSPredicate(format: "label ==[c] '\(productTypeLabel)'")

        // the common fields on add product screen
        XCTAssertTrue(app.cells["product-review-cell"].exists)
        XCTAssertTrue(app.staticTexts.containing(productTypeLabelPredicate).firstMatch.exists)

        // different product types display different fields on add product screen
        // this is to validate that the correct screens are displayed
        switch productType {
        case "physical", "virtual":
            XCTAssertTrue(app.staticTexts["Add Price"].exists)
            XCTAssertTrue(app.staticTexts["Inventory"].exists)
        case "variable":
            XCTAssertTrue(app.staticTexts["Add variations"].exists)
            XCTAssertTrue(app.staticTexts["Inventory"].exists)
        case "grouped":
            XCTAssertTrue(app.staticTexts["Add products to the group"].exists)
            XCTAssertFalse(app.staticTexts["Inventory"].exists)
        case "external":
            XCTAssertTrue(app.staticTexts["Add product link"].exists)
            XCTAssertTrue(app.staticTexts["Add Price"].exists)
            XCTAssertFalse(app.staticTexts["Inventory"].exists)
        default:
            XCTFail("Product Type \(productType) doesn't exist!")
        }
        return self
    }
}
