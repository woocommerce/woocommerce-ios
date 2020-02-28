import Foundation
import XCTest

class ProductsScreen: BaseScreen {

       struct ElementStringIDs {
        static let searchButton = "product-search-button"
        static let topBannerCollapseButton = "top-banner-view-expand-collapse-button"
        static let topBannerInfoLabel = "top-banner-view-info-label"
    }

    private let searchButton = XCUIApplication().buttons[ElementStringIDs.searchButton]
    private let topBannerCollapseButton = XCUIApplication().buttons[ElementStringIDs.topBannerCollapseButton]
    private let topBannerInfoLabel = XCUIApplication().staticTexts[ElementStringIDs.topBannerInfoLabel]

    static var isVisible: Bool {
        let searchButton = XCUIApplication().buttons[ElementStringIDs.searchButton]
        return searchButton.exists && searchButton.isHittable
    }

    init() {
        super.init(element: searchButton)
        XCTAssert(searchButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func collapseTopBannerIfNeeded() -> Self {

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
    func selectProduct(atIndex index: Int) -> SingleProductScreen {
        XCUIApplication().tables.cells.element(boundBy: index).tap()
        return SingleProductScreen()
    }
}
