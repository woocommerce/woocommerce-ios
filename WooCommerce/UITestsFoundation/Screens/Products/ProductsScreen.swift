import ScreenObject
import XCTest

public final class ProductsScreen: ScreenObject {

    private let topBannerCollapseButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["top-banner-view-expand-collapse-button"]
    }

    private let topBannerInfoLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["top-banner-view-info-label"]
    }

    private var topBannerInfoLabel: XCUIElement { topBannerInfoLabelGetter(app) }
    private var topBannerCollapseButton: XCUIElement { topBannerCollapseButtonGetter(app) }

    static var isVisible: Bool {
        (try? ProductsScreen().isLoaded) ?? false
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable next opening_brace
                { $0.buttons["product-add-button"] },
                { $0.buttons["product-scan-button"] },
                { $0.buttons["product-search-button"]}
                // swiftlint:enable next opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    public func collapseTopBannerIfNeeded() -> Self {

        /// Without the info label, we don't need to collapse the top banner
        guard topBannerInfoLabel.waitForExistence(timeout: 3) else {
           return self
        }

        /// If the banner isn't present, there's no need to collapse it
        guard topBannerCollapseButton.waitForExistence(timeout: 3) else {
            return self
        }

        topBannerCollapseButton.tap()
        return self
    }

    @discardableResult
    public func selectProductByIndex(atIndex index: Int) throws -> SingleProductScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleProductScreen()
    }

    public func selectProductByName(name: String) throws -> SingleProductScreen {
        app.tables.cells.staticTexts[name].tap()
        return try SingleProductScreen()
    }

    public func verifyProductOnProductsScreen(count: Int, name: String, status: String) throws -> ProductsScreen {
        XCTAssertTrue(try app.getTextVisibilityCount(text: name) == 1, "Product name does not exist!")
        XCTAssertTrue(app.tables.cells.count == count, "Expecting \(count) products, got \(app.tables.cells.count) instead!")
        XCTAssertTrue(try app.getTextVisibilityCount(text: status) > 0, "Stock status does not exist!")

        return try ProductsScreen()
    }

    public func verifyProductScreenLoaded() throws -> ProductsScreen {
        XCTAssertTrue(isLoaded)
        return try ProductsScreen()
    }
}
