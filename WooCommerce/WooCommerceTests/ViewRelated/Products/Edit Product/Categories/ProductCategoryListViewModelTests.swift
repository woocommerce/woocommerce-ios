import XCTest

@testable import WooCommerce
@testable import Yosemite
@testable import Networking


/// Tests for `ProductCategoryListViewModel`.
///
final class ProductCategoryListViewModelTests: XCTestCase {

    func testsCategoriesAreSelectedIfTheyArePartOfMainProduct() {
        // Given
        let categories = sampleCategories(count: 3)
        let product = MockProduct().product(categories: categories)
        let viewModel = ProductCategoryListViewModel(product: product)

        // When
        for category in categories {
            let isCategorySelected = viewModel.isCategorySelected(category)

            // Then
            XCTAssertTrue(isCategorySelected)
        }
    }

    func testCategoryIsNotSelectedIfItsNotPartOfMainProduct() {
        // Given
        let category = sampleCategory(categoryID: 1, name: "1")
        let product = MockProduct().product(categories: [])
        let viewModel = ProductCategoryListViewModel(product: product)

        // When
        let isCategorySelected = viewModel.isCategorySelected(category)

        // Then
        XCTAssertFalse(isCategorySelected)
    }

    func testItTransitionsToSyncedStateAfterSynchronizingCategories() {
        // Given
        let exp = expectation(description: #function)
        let product = MockProduct().product()
        let viewModel = ProductCategoryListViewModel(product: product)
        let storesManager = MockProductCategoryStoresManager()
        storesManager.productCategoryResponse = nil
        ServiceLocator.setStores(storesManager)

        // When
        viewModel.performFetch()
        viewModel.observeCategoryListStateChanges { state in
            if state == .synced {
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(storesManager.numberOfResponsesConsumed, 1)
    }

    func testItTransitionsToFailedStateAfterSynchronizingCategoriesErrors() {
        // Given
        let exp = expectation(description: #function)
        let product = MockProduct().product()
        let viewModel = ProductCategoryListViewModel(product: product)
        let storesManager = MockProductCategoryStoresManager()
        let rawError = NSError(domain: "Category Error", code: 1, userInfo: nil)
        let error = ProductCategoryActionError.categoriesSynchronization(pageNumber: 1, rawError: rawError)
        storesManager.productCategoryResponse = error
        ServiceLocator.setStores(storesManager)

        // When
        viewModel.performFetch()
        viewModel.observeCategoryListStateChanges { state in
            if case .failed = state {
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(storesManager.numberOfResponsesConsumed, 1)
    }
}

private extension ProductCategoryListViewModelTests {
    func sampleCategories(count: Int64) -> [ProductCategory] {
        return (0..<count).map {
            return sampleCategory(categoryID: $0, name: String($0))
        }
    }

    func sampleCategory(categoryID: Int64, name: String) -> ProductCategory {
        return ProductCategory(categoryID: categoryID, siteID: 123, parentID: 0, name: name, slug: "")
    }
}

/// Mock Product Category Store Manager
///
private final class MockProductCategoryStoresManager: DefaultStoresManager {

    /// Set mockup responses to be dispatched upon Product Category Actions.
    ///
    var productCategoryResponse: ProductCategoryActionError?

    /// Indicates how many times respones where consumed
    ///
    private(set) var numberOfResponsesConsumed = 0

    init() {
        super.init(sessionManager: SessionManager.testingInstance)
    }

    override func dispatch(_ action: Action) {
        if let productCategoryAction = action as? ProductCategoryAction {
            handleProductCategoryAction(productCategoryAction)
        }
    }

    private func handleProductCategoryAction(_ action: ProductCategoryAction) {
        switch action {
        case let .synchronizeProductCategories(_, _, onCompletion):
            numberOfResponsesConsumed = numberOfResponsesConsumed + 1
            onCompletion(productCategoryResponse)
        }
    }
}
