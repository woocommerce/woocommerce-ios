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

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        network = MockupNetwork(useResponseQueue: true)
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

    func testSynchronizeProductCategoriesReturnsCategoriesUponSuccessfulResponse() throws {
        // Given a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: ProductCategoryActionError?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then a valid set of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 2)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductCategoriesReturnsCategoriesUponPaginatedResponse() throws {
        // Given a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-extra")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: ProductCategoryActionError?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then a the combined set of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 3)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductCategoriesUpdatesStoredCategoriesSuccessfulResponse() {
        // Given an initial stored category and a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        let initialCategory = sampleCategory(categoryID: 20)
        storageManager.insertSampleProductCategory(readOnlyProductCategory: initialCategory)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: ProductCategoryActionError?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then the initial category should have it's values updated
        let updatedCategory = viewStorage.loadProductCategory(siteID: sampleSiteID, categoryID: initialCategory.categoryID)
        XCTAssertNotEqual(initialCategory.parentID, updatedCategory?.parentID)
        XCTAssertNotEqual(initialCategory.name, updatedCategory?.name)
        XCTAssertNotEqual(initialCategory.slug, updatedCategory?.slug)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductCategoriesReturnsErrorUponPaginatedReponseError() {
        // Given a stubed first page category response and second page generic-error network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: ProductCategoryActionError?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then first page of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 2)

        // And error should contain correct fromPageNumber
        switch errorResponse {
        case let .categoriesSynchronization(pageNumber, _):
            XCTAssertEqual(pageNumber, 2)
        case .none:
            XCTFail("errorResponse should not be nil")
        }

    }

    func testSynchronizeProductCategoriesReturnsErrorUponReponseError() {
        // Given a stubed generic-error network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: ProductCategoryActionError?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func testSynchronizeProductCategoriesReturnsErrorUponEmptyResponse() {
        // Given a an empty network response
        let expectation = self.expectation(description: #function)
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: ProductCategoryActionError?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { error in
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func testSynchronizeProductCategoriesDeletesUnusedCategories() {
        // Given some stored product categories without product relationships
        let expectation = self.expectation(description: #function)
        let sampleCategories = (1...5).map { id in
            return sampleCategory(categoryID: id)
        }
        sampleCategories.forEach { category in
            storageManager.insertSampleProductCategory(readOnlyProductCategory: category)
        }
        XCTAssertEqual(storedProductCategoriesCount, sampleCategories.count)

        // When dispatching a `synchronizeProductCategories` action
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID, fromPageNumber: defaultPageNumber) { _ in
            expectation.fulfill()
        }
        store.onAction(action)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then new categories should be stored and old categories should be deleted
        XCTAssertEqual(storedProductCategoriesCount, 2)
    }
}

private extension ProductCategoryStoreTests {
    func sampleCategory(categoryID: Int64) -> Networking.ProductCategory {
        return Networking.ProductCategory(categoryID: categoryID, siteID: sampleSiteID, parentID: 0, name: "Sample", slug: "Sample")
    }
}
