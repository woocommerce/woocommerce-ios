import ScreenObject
import XCTest

public final class ProductsScreen: ScreenObject {

    private let productAddButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["product-add-button"]
    }

    private let productSearchButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["product-search-button"]
    }

    private let topBannerViewExpandButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["top-banner-view-expand-collapse-button"]
    }

    private let topBannerViewInfoLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["top-banner-view-info-label"]
    }

    private var productAddButton: XCUIElement { productAddButtonGetter(app) }
    private var productSearchButton: XCUIElement { productSearchButtonGetter(app) }
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
    public func selectAddProduct() -> Self {
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
    public func selectProduct(atIndex index: Int) throws -> SingleProductScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleProductScreen()
    }

    @discardableResult
    public func selectProduct(byName name: String) throws -> SingleProductScreen {
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

    public func selectProductType(productType: String) throws -> SingleProductScreen {
        let productTypeLabel = NSPredicate(format: "label CONTAINS[c] %@", productType)
        app.staticTexts.containing(productTypeLabel).firstMatch.tap()
        return try SingleProductScreen()
    }

    public func selectSearchButton() throws -> ProductSearchScreen {
        productSearchButton.tap()
        return try ProductSearchScreen()
    }
}
