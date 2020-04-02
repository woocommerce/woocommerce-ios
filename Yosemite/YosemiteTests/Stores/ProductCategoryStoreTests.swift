import XCTest
@testable import Yosemite
@testable import Networking


/// ProductCategoryStore Unit Tests
///
final class ProductCategoryStoreTests: XCTestCase {
    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Store
    ///
    private var store: ProductCategoryStore!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 75

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        network = MockupNetwork()
        store = ProductCategoryStore(dispatcher: Dispatcher(),
                                     storageManager: MockupStorageManager(),
                                     network: network)
    }

    override func tearDown() {
        store = nil
        network = nil

        super.tearDown()
    }

    func testRetrieveProductCategoriesReturnsCategoriesUponSuccessfulResponse() throws {
        // Given a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")

        // When dispatching a `retrieveProductCategories` action
        let action = ProductCategoryAction.retrieveProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            // Then a valid set of categories should be returned
            guard let categories = categories else {
                return XCTFail("Categories should not be nil.")
            }
            XCTAssertFalse(categories.isEmpty)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testRetrieveProductCategoriesReturnsErrorUponReponseError() {
        // Given a stubed generic-error network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")

        // When dispatching a `retrieveProductCategories` action
        let action = ProductCategoryAction.retrieveProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            // Then no categories should be returned
            XCTAssertNil(categories)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testRetrieveProductCategoriesReturnsErrorUponEmptyResponse() {
        // Given a an empty network response
        let expectation = self.expectation(description: #function)

        // When dispatching a `retrieveProductCategories` action
        let action = ProductCategoryAction.retrieveProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            // Then no categories should be returned
            XCTAssertNil(categories)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
