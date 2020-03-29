import XCTest
@testable import Yosemite
@testable import Networking


/// ProductCategoryStore Unit Tests
///
final class ProductCategoryStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

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
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
        store = ProductCategoryStore(dispatcher: dispatcher,
                                     storageManager: storageManager,
                                     network: network)
    }

    override func tearDown() {
        store = nil
        dispatcher = nil
        storageManager = nil
        network = nil

        super.tearDown()
    }

    func testRetrieveProductCategoriesReturnsCategoriesUponSuccessfulResponse() throws {
        let expectation = self.expectation(description: #function)

        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")

        let action = ProductCategoryAction.retrieveProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
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
        let expectation = self.expectation(description: #function)

        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        let action = ProductCategoryAction.retrieveProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            XCTAssertNil(categories)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testRetrieveProductCategoriesReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: #function)

        let action = ProductCategoryAction.retrieveProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            XCTAssertNil(categories)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
