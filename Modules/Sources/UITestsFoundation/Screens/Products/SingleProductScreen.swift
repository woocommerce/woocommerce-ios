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
            expectedElementGetters: [ {$0.tables["product-form"]} ],
            app: app
        )
    }

    @discardableResult
    public func goBackToProductList() throws -> ProductsScreen {
        let navigationBar = app.navigationBars.element(boundBy: 0)
        // iOS 27 labels the system back button "Back" instead of the previous screen's title.
        let systemBackButton = navigationBar.buttons["BackButton"]
        let navBackButton = systemBackButton.exists ? systemBackButton : navigationBar.buttons.element(boundBy: 0)
        // If split view is enabled, back button is not shown in the product form navigation bar.
        if navBackButton.exists && !app.buttons["product-add-button"].isHittable {
            navBackButton.tap()
        }
        return try ProductsScreen()
    }

    @discardableResult
    public func verifyProduct(product: ProductData) throws -> Self {
        XCTAssertTrue(productFormTable.staticTexts["product-stock-status-\(product.stock_status)"].exists)
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
        XCTAssertTrue(app.cells["product-linked-products-promo-cell"].exists)
        XCTAssertTrue(app.textViews[productName].exists)

        // different product types display different fields on the published product screen
        // this is to validate that the correct screens are displayed
        switch productType {
        case "physical", "virtual":
            XCTAssertTrue(app.cells["product-price-cell"].exists)
        case "variable":
            XCTAssertTrue(app.cells["product-variations-cell"].exists)
        case "grouped":
            XCTAssertTrue(app.cells["product-grouped-products-cell"].exists)
        case "external":
            XCTAssertTrue(app.cells["product-external-url-cell"].exists)
        default:
            XCTFail("Product Type \(productType) doesn't exist!")
        }
    }

    public func verifyProductTypeScreenLoaded(productType: String) throws -> Self {
        let typeID = ["physical": "simple", "virtual": "simpleVirtual", "external": "affiliate"][productType] ?? productType

        // the common fields on add product screen
        XCTAssertTrue(app.cells["product-review-cell"].exists)
        XCTAssertTrue(productFormTable.staticTexts["product-type-\(typeID)"].exists)

        // different product types display different fields on add product screen
        // this is to validate that the correct screens are displayed
        switch productType {
        case "physical", "virtual":
            XCTAssertTrue(app.cells["product-price-cell"].exists)
            XCTAssertTrue(app.cells["product-inventory-cell"].exists)
        case "variable":
            XCTAssertTrue(app.cells["product-variations-cell"].exists)
            XCTAssertTrue(app.cells["product-inventory-cell"].exists)
        case "grouped":
            XCTAssertTrue(app.cells["product-grouped-products-cell"].exists)
            XCTAssertFalse(app.cells["product-inventory-cell"].exists)
        case "external":
            XCTAssertTrue(app.cells["product-external-url-cell"].exists)
            XCTAssertTrue(app.cells["product-price-cell"].exists)
            XCTAssertFalse(app.cells["product-inventory-cell"].exists)
        default:
            XCTFail("Product Type \(productType) doesn't exist!")
        }
        return self
    }
}
