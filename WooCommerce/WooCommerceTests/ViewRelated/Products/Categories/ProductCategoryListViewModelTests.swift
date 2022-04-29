import XCTest

@testable import WooCommerce
@testable import Yosemite
@testable import Networking
@testable import Storage


/// Tests for `ProductCategoryListViewModel`.
///
final class ProductCategoryListViewModelTests: XCTestCase {

    private var storesManager: MockProductCategoryStoresManager!
    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storesManager = MockProductCategoryStoresManager()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        super.tearDown()
        storesManager = nil
        storageManager = nil
    }

    func test_resetSelectedCategories_then_it_does_not_return_any_view_model() {
        // Given
        let exp = expectation(description: #function)
        let viewModel = ProductCategoryListViewModel(siteID: 0, storesManager: storesManager)
        let productCategory = ProductCategory(categoryID: 443, siteID: 123, parentID: 0, name: name, slug: "")

        // When
        viewModel.performFetch()
        viewModel.observeCategoryListStateChanges { state in
            if state == .synced {
                viewModel.addAndSelectNewCategory(category: productCategory)
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

        let passedCategory: Yosemite.ProductCategory? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let viewModel = ProductCategoryListViewModel(siteID: 0, storesManager: self.storesManager, onProductCategorySelection: { category in
                promise(category)
            })

            viewModel.addAndSelectNewCategory(category: productCategory)

        }

        XCTAssertEqual(passedCategory, productCategory)
    }

    func test_synchronize_categories_then_it_transitions_to_synced_state() {
        // Given
        let exp = expectation(description: #function)
        let siteID: Int64 = 1
        let viewModel = ProductCategoryListViewModel(siteID: siteID, storesManager: storesManager)
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


    func test_synchronize_categories_errors_then_it_transitions_to_failed_state() {
        // Given
        let exp = expectation(description: #function)
        let siteID: Int64 = 1
        let viewModel = ProductCategoryListViewModel(siteID: siteID, storesManager: storesManager)
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

    func test_reloadData_then_it_calls_reload_needed() {
        // Given
        let siteID: Int64 = 1
        let viewModel = ProductCategoryListViewModel(siteID: siteID, storesManager: storesManager)
        var reloadNeededIsCalled = false
        viewModel.observeReloadNeeded {
            reloadNeededIsCalled = true
        }

        // When
        viewModel.reloadData()

        // Then
        XCTAssertTrue(reloadNeededIsCalled)
    }

    func test_selectedCategories_are_updated_with_initially_selected_IDs() {
        // Given
        let siteID: Int64 = 132
        let category = Yosemite.ProductCategory(categoryID: 33, siteID: siteID, parentID: 1, name: "Test", slug: "test")
        insert(category)

        // When
        let viewModel = ProductCategoryListViewModel(siteID: siteID, selectedCategoryIDs: [category.categoryID], storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedCategories.count, 1)
        XCTAssertEqual(viewModel.selectedCategories.first?.categoryID, category.categoryID)
    }
}

// MARK: - Utils
private extension ProductCategoryListViewModelTests {
    func insert(_ readOnlyProductCategory: Yosemite.ProductCategory) {
        let category = storage.insertNewObject(ofType: StorageProductCategory.self)
        category.update(with: readOnlyProductCategory)
    }

    func insert(_ readOnlyProductCategories: [Yosemite.ProductCategory]) {
        for readOnlyProductCategory in readOnlyProductCategories {
            let category = storage.insertNewObject(ofType: StorageProductCategory.self)
            category.update(with: readOnlyProductCategory)
        }
    }
}
