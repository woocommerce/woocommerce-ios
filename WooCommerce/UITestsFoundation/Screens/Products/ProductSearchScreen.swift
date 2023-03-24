import ScreenObject
import XCTest

public final class ProductSearchScreen: ScreenObject {

    private let searchTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.descendants(matching: .other).element(matching: .any, identifier: "product-search-screen-search-field")
    }

    private var searchTextField: XCUIElement { searchTextFieldGetter(app) }
    private var updatedSearchResultsID = "updated-search-results-table-view"
    public static let defaultSearchResultsID = "default-search-results-table-view"

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ searchTextFieldGetter ],
            app: app
        )
    }

    public func enterSearchCriteria(text: String) throws -> Self {
        searchTextField.tap()
        searchTextField.enterText(text: text)
        return self
    }

    @discardableResult
    public func verifyNumberOfProductsOnSearchResults(expectedNumberOfProducts: Int, accessibilityId: String? = defaultSearchResultsID) throws -> Self {
        let productTableView = app.tables.matching(identifier: accessibilityId!)
        XCTAssert(productTableView.element.waitForExistence(timeout: 5), "Product list not displayed!")

        let expectedCount = expectedNumberOfProducts
        let actualCount = productTableView.cells.count

        XCTAssertTrue(expectedCount == actualCount, "Expected \(expectedCount) products but found \(actualCount) instead!")

        return self
    }

    public func verifyProductSearchResults(expectedProduct: ProductData) throws {
        try verifyNumberOfProductsOnSearchResults(expectedNumberOfProducts: 1, accessibilityId: updatedSearchResultsID)

        let productsTableView = app.tables.matching(identifier: updatedSearchResultsID)
        productsTableView.element.assertTextVisibilityCount(textToFind: String(expectedProduct.name))
        productsTableView.element.assertTextVisibilityCount(textToFind: String(expectedProduct.stock_status))
    }
}
