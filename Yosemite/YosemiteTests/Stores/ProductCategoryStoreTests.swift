import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking


/// ProductCategoryStore Unit Tests
///
final class ProductCategoryStoreTests: XCTestCase {
    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience Property: Returns stored product categories count.
    ///
    private var storedProductCategoriesCount: Int {
        return viewStorage.countObjects(ofType: Storage.ProductCategory.self)
    }

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
        storageManager = MockupStorageManager()
        store = ProductCategoryStore(dispatcher: Dispatcher(),
                                     storageManager: storageManager,
                                     network: network)
    }

    override func tearDown() {
        store = nil
        network = nil
        storageManager = nil

        super.tearDown()
    }

    func testRetrieveProductCategoriesReturnsCategoriesUponSuccessfulResponse() throws {
        // Given a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: Error?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then a valid set of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 2)
        XCTAssertNil(errorResponse)
    }

    func testRetrieveProductCategoriesReturnsErrorUponReponseError() {
        // Given a stubed generic-error network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: Error?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                        pageNumber: defaultPageNumber,
                                                                        pageSize: defaultPageSize) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func testRetrieveProductCategoriesReturnsErrorUponEmptyResponse() {
        // Given a an empty network response
        let expectation = self.expectation(description: #function)
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: Error?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                        pageNumber: defaultPageNumber,
                                                                        pageSize: defaultPageSize) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(errorResponse)
    }
}
