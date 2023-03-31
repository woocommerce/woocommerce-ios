import ScreenObject
import XCTest

public final class ProductsScreen: ScreenObject {

    private let productAddButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["product-add-button"]
    }

    private let productSearchButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["product-search-button"]
    }

    private let productFilterButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["product-filter-button"]
    }

    private let productsTableViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["products-table-view"]
    }

    private let topBannerViewExpandButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["top-banner-view-expand-collapse-button"]
    }

    private let topBannerViewInfoLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["top-banner-view-info-label"]
    }

    private var productAddButton: XCUIElement { productAddButtonGetter(app) }
    private var productSearchButton: XCUIElement { productSearchButtonGetter(app) }
    private var productFilterButton: XCUIElement { productFilterButtonGetter(app) }
    private var productsTableView: XCUIElement { productsTableViewGetter(app) }
    private var topBannerViewExpandButton: XCUIElement { topBannerViewExpandButtonGetter(app) }
    private var topBannerViewInfoLabel: XCUIElement { topBannerViewInfoLabelGetter(app) }

    public let tabBar: TabNavComponent

    static var isVisible: Bool {
        (try? ProductsScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent(app: app)

        try super.init(
            expectedElementGetters: [ productAddButtonGetter, productSearchButtonGetter ],
            app: app
        )
    }

    @discardableResult
    public func tapAddProduct() -> Self {
        guard productAddButton.waitForExistence(timeout: 3) else {
            return self
        }

        productAddButton.tap()
        return self
    }

    @discardableResult
    public func collapseTopBannerIfNeeded() -> Self {

        /// Without the info label, we don't need to collapse the top banner
        guard topBannerViewInfoLabel.waitForExistence(timeout: 3) else {
           return self
        }

        /// If the banner isn't present, there's no need to collapse it
        guard topBannerViewExpandButton.waitForExistence(timeout: 3) else {
            return self
        }

        topBannerViewExpandButton.tap()
        return self
    }

    @discardableResult
    public func tapProduct(atIndex index: Int) throws -> SingleProductScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleProductScreen()
    }

    @discardableResult
    public func tapProduct(byName name: String) throws -> SingleProductScreen {
        app.tables.cells.staticTexts[name].tap()
        return try SingleProductScreen()
    }

    @discardableResult
    public func verifyProductList(products: [ProductData]) throws -> Self {
        app.assertTextVisibilityCount(textToFind: products[0].name, expectedCount: 1)
        app.assertElement(matching: products[0].name, existsOnCellWithIdentifier: products[0].stock_status)
        XCTAssertEqual(products.count, app.tables.cells.count, "Expected '\(products.count)' products but found '\(app.tables.cells.count)' instead!")

        return self
    }

    @discardableResult
    public func verifyProductsScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    public func tapProductType(productType: String) throws -> SingleProductScreen {
        let productTypeLabel = NSPredicate(format: "label CONTAINS[c] %@", productType)
        app.staticTexts.containing(productTypeLabel).firstMatch.tap()
        return try SingleProductScreen()
    }

    public func tapSearchButton() throws -> ProductSearchScreen {
        productSearchButton.tap()
        return try ProductSearchScreen()
    }

    public func tapFilterButton() throws -> ProductFilterScreen {
        productFilterButton.tap()
        return try ProductFilterScreen()
    }

    @discardableResult
    public func verifyProductFilterResults(products: [ProductData], filter: String) throws -> Self {
        let filteredProducts = products.filter { $0.stock_status == filter.lowercased() }

        for product in filteredProducts {
            productsTableView.assertTextVisibilityCount(textToFind: product.name, expectedCount: 1)
        }

        productsTableView.assertTextVisibilityCount(textToFind: filter, expectedCount: filteredProducts.count)

        return self
    }
}
