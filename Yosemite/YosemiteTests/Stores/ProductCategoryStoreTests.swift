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

    func testSynchronizeProductCategoriesReturnsCategoriesUponSuccessfulResponse() throws {
        // Given a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: Error?
        var categoriesResponse: [Networking.ProductCategory]?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            categoriesResponse = categories
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then a valid set of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 2)
        XCTAssertNotNil(categoriesResponse)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductCategoriesUpdatesStoredCategoriesSuccessfulResponse() {
        // Given an initial stored category and a stubed product-categories network response
        let expectation = self.expectation(description: #function)
        let initialCategory = sampleCategory(categoryID: 20)
        storageManager.insertSampleProductCategory(readOnlyProductCategory: initialCategory)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")

        // When dispatching a `synchronizeProductCategories` action
        var errorResponse: Error?
        var categoriesResponse: [Networking.ProductCategory]?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { categories, error in
            categoriesResponse = categories
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then the initial category should have it's values updated
        let updatedCategory = viewStorage.loadProductCategory(siteID: sampleSiteID, categoryID: initialCategory.categoryID)
        XCTAssertNotEqual(initialCategory.parentID, updatedCategory?.parentID)
        XCTAssertNotEqual(initialCategory.name, updatedCategory?.name)
        XCTAssertNotEqual(initialCategory.slug, updatedCategory?.slug)
        XCTAssertNotNil(categoriesResponse)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductCategoriesReturnsErrorUponReponseError() {
        // Given a stubed generic-error network response
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var categoriesResponse: [Networking.ProductCategory]?
        var errorResponse: Error?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                        pageNumber: defaultPageNumber,
                                                                        pageSize: defaultPageSize) { categories, error in
            categoriesResponse = categories
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNil(categoriesResponse)
        XCTAssertNotNil(errorResponse)
    }

    func testSynchronizeProductCategoriesReturnsErrorUponEmptyResponse() {
        // Given a an empty network response
        let expectation = self.expectation(description: #function)
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        var categoriesResponse: [Networking.ProductCategory]?
        var errorResponse: Error?
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                        pageNumber: defaultPageNumber,
                                                                        pageSize: defaultPageSize) { categories, error in
            categoriesResponse = categories
            errorResponse = error
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNil(categoriesResponse)
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
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: sampleSiteID,
                                                                     pageNumber: defaultPageNumber,
                                                                     pageSize: defaultPageSize) { _, _ in
            expectation.fulfill()
        }
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then new categories should be stored and old categories should be deleted
        XCTAssertEqual(storedProductCategoriesCount, 2)
    }
}

private extension ProductCategoryStoreTests {
    func sampleCategory(categoryID: Int64) -> Networking.ProductCategory {
        return Networking.ProductCategory(categoryID: categoryID, siteID: sampleSiteID, parentID: 0, name: "Sample", slug: "Sample")
    }
}
