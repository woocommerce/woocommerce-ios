import XCTest

@testable import WooCommerce
@testable import Yosemite
@testable import Networking


/// Tests for `ProductCategoryListViewModel`.
///
final class ProductCategoryListViewModelTests: XCTestCase {

    private var storesManager: MockProductCategoryStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockProductCategoryStoresManager()
    }

    override func tearDown() {
        super.tearDown()
        storesManager = nil
    }

    func test_resetSelectedCategories_then_it_does_not_return_any_view_model() {
        // Given
        let exp = expectation(description: #function)
        let viewModel = ProductCategoryListViewModel(storesManager: storesManager, siteID: 0)

        // When
        viewModel.performFetch()
        viewModel.observeCategoryListStateChanges { state in
            if state == .synced {
                viewModel.selectOrDeselectCategory(index: 0)
                viewModel.resetSelectedCategories()

                exp.fulfill()
            }
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertTrue(viewModel.categoryViewModels.isEmpty)
    }

    func test_select_category_then_it_calls_onProductCategorySelection() {
        let productCategory = ProductCategory(categoryID: 443, siteID: 123, parentID: 0, name: name, slug: "")

        let passedCategory: ProductCategory? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let viewModel = ProductCategoryListViewModel(storesManager: self.storesManager, siteID: 0, onProductCategorySelection: { category in
                promise(category)

            })

            viewModel.addAndSelectNewCategory(category: productCategory)

        }

        XCTAssertEqual(passedCategory, productCategory)
    }

    func testItTransitionsToSyncedStateAfterSynchronizingCategories() {
        // Given
        let exp = expectation(description: #function)
        let siteID: Int64 = 1
        let viewModel = ProductCategoryListViewModel(storesManager: storesManager, siteID: siteID)
        storesManager.productCategoryResponse = nil

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
        let siteID: Int64 = 1
        let viewModel = ProductCategoryListViewModel(storesManager: storesManager, siteID: siteID)
        let rawError = NSError(domain: "Category Error", code: 1, userInfo: nil)
        let error = ProductCategoryActionError.categoriesSynchronization(pageNumber: 1, rawError: rawError)
        storesManager.productCategoryResponse = error

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

    func testItCallsReloadNeededWhenRequested() {
        // Given
        let siteID: Int64 = 1
        let viewModel = ProductCategoryListViewModel(storesManager: storesManager, siteID: siteID)
        var reloadNeededIsCalled = false
        viewModel.observeReloadNeeded {
            reloadNeededIsCalled = true
        }

        // When
        viewModel.reloadData()

        // Then
        XCTAssertTrue(reloadNeededIsCalled)
    }
}
