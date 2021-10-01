import ScreenObject
import XCTest

public class ProductsScreen: ScreenObject {

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
                topBannerCollapseButtonGetter,
                topBannerInfoLabelGetter,
                // swiftlint:skip:next opening_brace
                { $0.buttons["product-search-button"] }
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
    public func selectProduct(atIndex index: Int) throws -> SingleProductScreen {
        XCUIApplication().tables.cells.element(boundBy: index).tap()
        return try SingleProductScreen()
    }
}
