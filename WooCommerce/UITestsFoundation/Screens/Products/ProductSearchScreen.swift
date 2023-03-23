import ScreenObject
import XCTest

public final class ProductSearchScreen: ScreenObject {

    private let searchTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.descendants(matching: .other).element(matching: .any, identifier: "product-search-screen-search-field")
    }

    private var searchTextField: XCUIElement { searchTextFieldGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ searchTextFieldGetter ],
            app: app
        )
    }

    @discardableResult
    public func enterSearchCriteria(text: String) throws -> Self {
        searchTextField.tap()
        searchTextField.enterText(text: text)
        return self
    }

    @discardableResult
    public func verifyNumberOfProductsDisplayed(expectedNumberOfProducts: Int, accessibilityId: String? = "default-search-results-list") throws -> Self {
        let productTableView = app.tables.matching(identifier: accessibilityId!)
        XCTAssert(productTableView.element.waitForExistence(timeout: 5), "Product list not displayed!")

        let expectedCount = expectedNumberOfProducts
        let actualCount = productTableView.cells.count

        XCTAssertTrue(expectedCount == actualCount, "Expected \(expectedCount) products but found \(actualCount) instead!")

        return self
    }

    public func verifyProductSearchResults(expectedProduct: ProductData) throws {
        try verifyNumberOfProductsDisplayed(expectedNumberOfProducts: 1, accessibilityId: "updated-search-results-list")

        let productsTableView = app.tables.matching(identifier: "updated-search-results-list")
        productsTableView.element.assertTextVisibilityCount(textToFind: String(expectedProduct.name))
        productsTableView.element.assertTextVisibilityCount(textToFind: String(expectedProduct.stock_status))
    }
}
