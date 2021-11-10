import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking


/// ProductCategoryStore Unit Tests
///
final class ProductCategoryStoreTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

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
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
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

    func test_synchronizeProductCategories_then_it_returns_categories_upon_successful_response() throws {
        // Given a stubed product-categories network response
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        let errorResponse: ProductCategoryActionError? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { error in
                promise(error)
            }

            self.store.onAction(action)
        }

        // Then a valid set of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 2)
        XCTAssertNil(errorResponse)
    }

    func test_synchronizeProductCategories_then_it_returns_categories_upon_paginated_response() throws {
        // Given a stubed product-categories network response
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-extra")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        let errorResponse: ProductCategoryActionError? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { error in
                promise(error)
            }

            self.store.onAction(action)
        }

        // Then a the combined set of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 3)
        XCTAssertNil(errorResponse)
    }

    func test_synchronizeProductCategories_then_it_updates_stored_categories_upon_succesful_response() {
        // Given an initial stored category and a stubed product-categories network response
        let initialCategory = sampleCategory(categoryID: 20)
        storageManager.insertSampleProductCategory(readOnlyProductCategory: initialCategory)
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-empty")

        // When dispatching a `synchronizeProductCategories` action
        let errorResponse: ProductCategoryActionError? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { error in
                promise(error)
            }

            self.store.onAction(action)
        }


        // Then the initial category should have it's values updated
        let updatedCategory = viewStorage.loadProductCategory(siteID: sampleSiteID, categoryID: initialCategory.categoryID)
        XCTAssertNotEqual(initialCategory.parentID, updatedCategory?.parentID)
        XCTAssertNotEqual(initialCategory.name, updatedCategory?.name)
        XCTAssertNotEqual(initialCategory.slug, updatedCategory?.slug)
        XCTAssertNil(errorResponse)
    }

    func test_synchronizeProductCategories_then_it_returns_error_upon_paginated_response_error() {
        // Given a stubed first page category response and second page generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "categories-all")
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        let errorResponse: ProductCategoryActionError? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { error in
                promise(error)
            }

            self.store.onAction(action)
        }

        // Then first page of categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 2)

        // And error should contain correct fromPageNumber
        switch errorResponse {
        case let .categoriesSynchronization(pageNumber, _):
            XCTAssertEqual(pageNumber, 2)
        case .none:
            XCTFail("errorResponse should not be nil")
        default:
            break
        }
    }

    func test_synchronizeProductCategories_then_it_returns_error_upon_response_error() {
        // Given a stubed generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        let errorResponse: ProductCategoryActionError? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { error in
               promise(error)
            }
            self.store.onAction(action)
        }

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func test_synchronizeProductCategories_then_it_returns_error_upon_empty_response() {
        // Given a an empty network response
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `synchronizeProductCategories` action
        let errorResponse: ProductCategoryActionError? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { error in
                promise(error)
            }
            self.store.onAction(action)
        }

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func test_addProductCategory_then_it_adds_storedCategory_when_a_successful_response() {
        // Given a stubed product category network response
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "category")

        // When dispatching a `addProductCategory` action
        var result: Result<Networking.ProductCategory, Error>?
        waitForExpectation { (exp) in
            let action = ProductCategoryAction.addProductCategory(siteID: sampleSiteID, name: "Dress", parentID: 0) { aResult in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }


        // Then the category should be added
        let addedCategory = viewStorage.loadProductCategory(siteID: sampleSiteID, categoryID: 104)
        XCTAssertNotNil(addedCategory)
        assertAddedCategoryTookDataFromMockedNetworkData(addedCategory)
        XCTAssertNil(result?.failure)
    }

    func test_addProductCategory_then_it_returns_error_upon_response_error() {
        // Given a stubed generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/categories", filename: "generic_error")
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `addProductCategory` action
        var result: Result<Networking.ProductCategory, Error>?
        waitForExpectation { (exp) in
            let action = ProductCategoryAction.addProductCategory(siteID: sampleSiteID, name: "Dress", parentID: 0) { aResult in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }


        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(result?.failure)
    }

    func test_addProductCategory_then_it_returns_error_upon_empty_error() {
        // Given a an empty network response
        XCTAssertEqual(storedProductCategoriesCount, 0)

        // When dispatching a `addProductCategory` action
        var result: Result<Networking.ProductCategory, Error>?
        waitForExpectation { (exp) in
            let action = ProductCategoryAction.addProductCategory(siteID: sampleSiteID, name: "Dress", parentID: 0) { aResult in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then no categories should be stored
        XCTAssertEqual(storedProductCategoriesCount, 0)
        XCTAssertNotNil(result?.failure)
    }

    func test_synchronizeProductCategories_then_it_deletes_unused_categories() {
        // Given some stored product categories without product relationships
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

        let _: Bool = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategories(siteID: self.sampleSiteID, fromPageNumber: self.defaultPageNumber) { _ in
                promise(true)
            }
            self.store.onAction(action)
        }

        // Then new categories should be stored and old categories should be deleted
        XCTAssertEqual(storedProductCategoriesCount, 2)
    }

    func test_synchronizeProductCategory_successfully_then_it_stores_the_requested_category() {
        let categoryID: Int64 = 123
        network.simulateResponse(requestUrlSuffix: "products/categories/\(categoryID)", filename: "category")

        let addedCategory: Storage.ProductCategory? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategory(siteID: self.sampleSiteID, categoryID: categoryID) { result in
                promise(self.viewStorage.loadProductCategory(siteID: self.sampleSiteID, categoryID: 104))
            }

            self.store.onAction(action)
        }

        assertAddedCategoryTookDataFromMockedNetworkData(addedCategory)
    }

    func test_synchronizeProductCategory_successfully_then_it_provides_the_requested_category() {
        let categoryID: Int64 = 123
        network.simulateResponse(requestUrlSuffix: "products/categories/\(categoryID)", filename: "category")

        let result: Result<Networking.ProductCategory, Error>? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategory(siteID: self.sampleSiteID, categoryID: categoryID) { result in
                promise(result)
            }

            self.store.onAction(action)
        }

        XCTAssertEqual(try result?.get().name, "Dress")
    }

    func test_synchronizeProductCategory_fails_with_resourceDoesNotExist_then_it_provides_right_error() {
        let categoryID: Int64 = 123
        network.simulateError(requestUrlSuffix: "products/categories/\(categoryID)", error: DotcomError.resourceDoesNotExist)

        let retrievedError: Error? = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = ProductCategoryAction.synchronizeProductCategory(siteID: self.sampleSiteID, categoryID: categoryID) { result in
                switch result {
                case .failure(let error):
                    promise(error)
                default:
                    break
                }
            }

            self.store.onAction(action)
        }

        guard let error = retrievedError as? ProductCategoryActionError,
              case .categoryDoesNotExistRemotely = error else {
            XCTFail()
            return
        }
    }
}

private extension ProductCategoryStoreTests {
    func sampleCategory(categoryID: Int64) -> Networking.ProductCategory {
        return Networking.ProductCategory(categoryID: categoryID, siteID: sampleSiteID, parentID: 0, name: "Sample", slug: "Sample")
    }

    func assertAddedCategoryTookDataFromMockedNetworkData(_ productCategory: Storage.ProductCategory?) {
        XCTAssertNotNil(productCategory)
        XCTAssertEqual(productCategory?.categoryID, 104)
        XCTAssertEqual(productCategory?.parentID, 0)
        XCTAssertEqual(productCategory?.siteID, sampleSiteID)
        XCTAssertEqual(productCategory?.name, "Dress")
        XCTAssertEqual(productCategory?.slug, "Shirt")
    }
}
