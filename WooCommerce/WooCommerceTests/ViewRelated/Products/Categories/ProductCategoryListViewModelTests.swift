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
}



/// Mock Product Category Store Manager
///
private final class MockProductCategoryStoresManager: DefaultStoresManager {

    /// Set mock responses to be dispatched upon Product Category Actions.
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
        default:
            return
        }
    }
}
