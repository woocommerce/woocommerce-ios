import XCTest

@testable import Networking
@testable import Storage
@testable import Yosemite

final class ProductVariationStoreTests: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing ProductID
    ///
    private let sampleProductID: Int64 = 282

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 75

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - ProductVariationAction.synchronizeProductVariations

    /// Verifies that `ProductVariationAction.synchronizeProductVariations` effectively persists any retrieved product variations.
    ///
    func testRetrieveProductVariationsEffectivelyPersisted() {
        let expectation = self.expectation(description: "Retrieve product variation list")
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations", filename: "product-variations-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 0)

        let action = ProductVariationAction.synchronizeProductVariations(siteID: sampleSiteID,
                                                                         productID: sampleProductID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductVariation.self), 8)
            XCTAssertNil(error)

            let sampleProductVariationID: Int64 = 1275
            let storedProductVariation = self.viewStorage.loadProductVariation(siteID: self.sampleSiteID, productVariationID: sampleProductVariationID)
            let readOnlyStoredProductVariation = storedProductVariation?.toReadOnly()
            XCTAssertNotNil(storedProductVariation)
            XCTAssertNotNil(readOnlyStoredProductVariation)
            XCTAssertEqual(readOnlyStoredProductVariation, self.sampleProductVariation(id: sampleProductVariationID))

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductVariationAction.synchronizeProductVariations` multiple times does not create duplicated objects.
    ///
    func testRetrieveProductVariationsCreateNoDuplicates() {
        let expectation = self.expectation(description: "Retrieve product variation list")
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations", filename: "product-variations-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 0)

        let action = ProductVariationAction.synchronizeProductVariations(siteID: sampleSiteID,
                                                                         productID: sampleProductID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let storedProductVariations = self.viewStorage.loadProductVariations(siteID: self.sampleSiteID, productID: self.sampleProductID)
            XCTAssertEqual(storedProductVariations?.count, 8)

            let sampleProductVariationID: Int64 = 1275
            let storedProductVariation = self.viewStorage.loadProductVariation(siteID: self.sampleSiteID, productVariationID: sampleProductVariationID)
            XCTAssertEqual(storedProductVariation?.toReadOnly(), self.sampleProductVariation(id: sampleProductVariationID))

            let action = ProductVariationAction.synchronizeProductVariations(siteID: self.sampleSiteID,
                                                                             productID: self.sampleProductID,
                                                                             pageNumber: self.defaultPageNumber,
                                                                             pageSize: self.defaultPageSize) { error in
                XCTAssertNil(error)

                let storedProductVariations = self.viewStorage.loadProductVariations(siteID: self.sampleSiteID, productID: self.sampleProductID)
                XCTAssertEqual(storedProductVariations?.count, 8)

                // Verifies the expected Product Variation is still correct.
                let sampleProductVariationID: Int64 = 1275
                let storedProductVariation = self.viewStorage.loadProductVariation(siteID: self.sampleSiteID, productVariationID: sampleProductVariationID)
                XCTAssertEqual(storedProductVariation?.toReadOnly(), self.sampleProductVariation(id: sampleProductVariationID))

                expectation.fulfill()
            }
            store.onAction(action)
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductVariationAction.synchronizeProductVariations` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveProductVariationsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve product variations error response")
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations", filename: "generic_error")

        let action = ProductVariationAction.synchronizeProductVariations(siteID: sampleSiteID,
                                                                         productID: sampleProductID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductVariationAction.synchronizeProductVariations` returns an error whenever there is no backend response.
    ///
    func testRetrieveProductVariationsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve product variations empty response")
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductVariationAction.synchronizeProductVariations(siteID: sampleSiteID,
                                                                         productID: sampleProductID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that syncing for the first page deletes stored models for the given site ID and product ID.
    ///
    func testSyncingProductVariationsOnTheFirstPageResetsStoredModels() {
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Inserts a Product Variation into the storage with two site IDs.
        let siteID1: Int64 = 134
        let siteID2: Int64 = 591

        let productID: Int64 = 123

        // This variation ID should not exist in the network response.
        let variationID: Int64 = 1

        storageManager.insertSampleProductVariation(readOnlyProductVariation: sampleProductVariation(siteID: siteID1,
                                                                                                     productID: productID,
                                                                                                     id: variationID))
        storageManager.insertSampleProductVariation(readOnlyProductVariation: sampleProductVariation(siteID: siteID2,
                                                                                                     productID: productID,
                                                                                                     id: variationID))

        let expectation = self.expectation(description: "Persist product variation list")

        network.simulateResponse(requestUrlSuffix: "products/\(productID)/variations", filename: "product-variations-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 2)

        let action = ProductVariationAction.synchronizeProductVariations(siteID: siteID1,
                                                                         productID: productID,
                                                                         pageNumber: Store.Default.firstPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            // The previously upserted ProductVariation for siteID1 should be deleted.
            let storedVariationForSite1 = self.viewStorage.loadProductVariation(siteID: siteID1, productVariationID: variationID)
            XCTAssertNil(storedVariationForSite1)

            // The previously upserted ProductVariation for siteID2 should stay in storage.
            let storedVariationForSite2 = self.viewStorage.loadProductVariation(siteID: siteID2, productVariationID: variationID)
            XCTAssertNotNil(storedVariationForSite2)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that syncing after the first page does not delete stored models for the given site ID and product ID.
    ///
    func testSyncingProductVariationsAfterTheFirstPage() {
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Inserts one ProductVariation into the storage.
        let siteID: Int64 = 134
        let productID: Int64 = 888

        // This variation ID should not exist in the network response.
        let variationID: Int64 = 1002

        storageManager.insertSampleProductVariation(readOnlyProductVariation: sampleProductVariation(siteID: siteID,
                                                                                                     productID: productID,
                                                                                                     id: variationID))

        let expectation = self.expectation(description: "Persist product variation list")

        network.simulateResponse(requestUrlSuffix: "products/\(productID)/variations", filename: "product-variations-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)

        let action = ProductVariationAction.synchronizeProductVariations(siteID: siteID,
                                                                         productID: productID,
                                                                         pageNumber: 3,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            // The previously upserted ProductVariation's should stay in storage.
            let storedVariation = self.viewStorage.loadProductVariation(siteID: siteID, productVariationID: variationID)
            XCTAssertNotNil(storedVariation)

            XCTAssertGreaterThan(self.viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that syncing for the first page does not delete stored ProductVariations if the API call fails.
    ///
    func testSyncingProductVariationsOnTheFirstPageDoesNotDeleteStoredProductsUponResponseError() {
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Inserts one ProductVariation into the storage.
        let siteID: Int64 = 134
        let productID: Int64 = 888

        // This variation ID should not exist in the network response.
        let variationID: Int64 = 1002

        storageManager.insertSampleProductVariation(readOnlyProductVariation: sampleProductVariation(siteID: siteID,
                                                                                                     productID: productID,
                                                                                                     id: variationID))

        let expectation = self.expectation(description: "Persist product variation list")

        network.simulateResponse(requestUrlSuffix: "products", filename: "generic_error")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)

        let action = ProductVariationAction.synchronizeProductVariations(siteID: siteID,
                                                                         productID: productID,
                                                                         pageNumber: Store.Default.firstPageNumber,
                                                                         pageSize: defaultPageSize) { error in
                                                                            XCTAssertNotNil(error)

            // The previously upserted Product's should stay in storage.
            let storedVariation = self.viewStorage.loadProductVariation(siteID: siteID, productVariationID: variationID)
            XCTAssertNotNil(storedVariation)

            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ProductVariationAction.retrieveProductVariation

    /// Verifies that `ProductVariationAction.retrieveProductVariation` effectively persists the retrieved product variation.
    ///
    func test_retrieveProductVariation_persists_the_ProductVariation() throws {
        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let sampleProductVariationID: Int64 = 1275
        let expectedProductVariation = sampleProductVariation(id: sampleProductVariationID)
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: sampleProductVariationID,
                                           thenReturn: .success(expectedProductVariation))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 0)

        // When
        let result: Result<Yosemite.ProductVariation, Error> = try waitFor { promise in
            let action = ProductVariationAction.retrieveProductVariation(siteID: self.sampleSiteID,
                                                                         productID: self.sampleProductID,
                                                                         variationID: sampleProductVariationID) { result in
                                                                            promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(try result.get())

        let storedProductVariation = viewStorage.loadProductVariation(siteID: sampleSiteID, productVariationID: sampleProductVariationID)
        XCTAssertNotNil(storedProductVariation)

        let readOnlyStoredProductVariation = storedProductVariation?.toReadOnly()
        XCTAssertEqual(readOnlyStoredProductVariation, expectedProductVariation)
    }

    /// Verifies that `ProductVariationAction.retrieveProductVariation` called multiple times does not create duplicated objects.
    ///
    func test_retrieveProductVariation_create_no_duplicates() throws {

        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let sampleProductVariationID: Int64 = 1275
        let expectedProductVariation = sampleProductVariation(id: sampleProductVariationID)
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: sampleProductVariationID,
                                           thenReturn: .success(expectedProductVariation))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 0)

        // When
        let result1: Result<Yosemite.ProductVariation, Error> = try waitFor { promise in
            let action = ProductVariationAction.retrieveProductVariation(siteID: self.sampleSiteID,
                                                                         productID: self.sampleProductID,
                                                                         variationID: sampleProductVariationID) { result in
                                                                            promise(result)
            }
            store.onAction(action)
        }

        let result2: Result<Yosemite.ProductVariation, Error> = try waitFor { promise in
            let action = ProductVariationAction.retrieveProductVariation(siteID: self.sampleSiteID,
                                                                         productID: self.sampleProductID,
                                                                         variationID: sampleProductVariationID) { result in
                                                                            promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)

        XCTAssertTrue(result1.isSuccess)
        XCTAssertNotNil(try result1.get())

        XCTAssertTrue(result2.isSuccess)
        XCTAssertNotNil(try result2.get())

        let storedProductVariation = viewStorage.loadProductVariation(siteID: sampleSiteID, productVariationID: sampleProductVariationID)
        XCTAssertNotNil(storedProductVariation)

        let readOnlyStoredProductVariation = storedProductVariation?.toReadOnly()
        XCTAssertEqual(readOnlyStoredProductVariation, expectedProductVariation)
    }

    /// Verifies that `ProductVariationAction.retrieveProductVariation` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveProductVariation_returns_expected_error() throws {

        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let sampleProductVariationID: Int64 = 1275
        let expectedError = ProductVariationLoadError.notFoundInStorage
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: sampleProductVariationID,
                                           thenReturn: .failure(expectedError))

        // When
        let result: Result<Yosemite.ProductVariation, Error> = try waitFor { promise in
            let action = ProductVariationAction.retrieveProductVariation(siteID: self.sampleSiteID,
                                                                         productID: self.sampleProductID,
                                                                         variationID: sampleProductVariationID) { result in
                                                                            promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 0)

        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? ProductVariationLoadError, expectedError)
    }

    // MARK: - ProductVariationAction.updateProductVariation

    /// Verifies that `ProductVariationAction.updateProductVariation` returns the expected `ProductVariation`.
    ///
    func testUpdatingProductVariationReturnsExpectedFieldsAndRelatedObjects() {
        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let productVariationID: Int64 = 17
        let expectedProductVariation = MockProductVariation()
            .productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: productVariationID)
            .copy(attributes: sampleProductVariationAttributes())
        let productVariation = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: productVariationID)
            .copy(description: "Wooooo", sku: "test-woo")
        remote.whenUpdatingProductVariation(siteID: sampleSiteID,
                                   productID: sampleProductID,
                                   productVariationID: productVariationID,
                                   thenReturn: .success(expectedProductVariation))

        // Saves an existing ProductVariation into storage.
        // Note: at least one field of `ProductVariation` before and after the update should be different.
        storageManager.insertSampleProductVariation(readOnlyProductVariation: productVariation)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductVariation.self), 1)

        // When
        var result: Result<Yosemite.ProductVariation, ProductUpdateError>?
        waitForExpectation { expectation in
            let action = ProductVariationAction.updateProductVariation(productVariation: productVariation) { aResult in
                result = aResult
                expectation.fulfill()
            }
            store.onAction(action)
        }

        // Then
        let updatedProductVariation = try? result?.get()
        XCTAssertEqual(updatedProductVariation, expectedProductVariation)

        let storedProductVariation = viewStorage.loadProductVariation(siteID: sampleSiteID, productVariationID: productVariationID)
        let readOnlyStoredProduct = storedProductVariation?.toReadOnly()
        XCTAssertEqual(readOnlyStoredProduct, expectedProductVariation)
    }

    /// Verifies that `ProductVariationAction.updateProductVariation` returns an error whenever there is an error response from the backend.
    ///
    func test_updateProductVariation_returns_error_upon_response_error() {
        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let productVariationID: Int64 = 17
        remote.whenUpdatingProductVariation(siteID: sampleSiteID,
                                   productID: sampleProductID,
                                   productVariationID: productVariationID,
                                   thenReturn: .failure(NSError(domain: "", code: 400, userInfo: nil)))
        // Saves an existing ProductVariation into storage.
        let productVariation = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: productVariationID)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: productVariation)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductVariation.self), 1)

        // When
        var result: Result<Yosemite.ProductVariation, ProductUpdateError>?
        waitForExpectation { expectation in
            let action = ProductVariationAction.updateProductVariation(productVariation: productVariation) { aResult in
                result = aResult
                expectation.fulfill()
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isFailure)

        // The existing ProductVariation should not be deleted.
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)
    }

    // MARK: `requestMissingVariations`

    func test_requestMissingVariations_only_completes_when_all_missing_variations_are_returned() throws {
        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let variation1 = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 1)
        let variation2 = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 2)
        // Saves a variation into storage.
        let variationInStorage = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 280)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variationInStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductVariation.self), 1)

        // Mocks remote result for missing variations.
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: variation1.productVariationID,
                                           thenReturn: .success(variation1))
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: variation2.productVariationID,
                                           thenReturn: .success(variation2))

        let orderItems = [
            sampleOrderItem(productID: sampleProductID, variationID: variation1.productVariationID),
            sampleOrderItem(productID: sampleProductID, variationID: variation2.productVariationID),
            sampleOrderItem(productID: sampleProductID, variationID: variationInStorage.productVariationID)
        ]
        let order = sampleOrder(items: orderItems)

        // When
        var error: Error?
        waitForExpectation(count: 1) { expectation in
            let action = ProductVariationAction.requestMissingVariations(for: order, onCompletion: { anError in
                error = anError
                expectation.fulfill()
            })
            store.onAction(action)
        }

        // Then
        XCTAssertNil(error)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 3)
    }

    func test_requestMissingVariations_does_not_make_network_requests_when_all_variations_are_in_storage() throws {
        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let variation1 = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 1)
        let variation2 = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 2)
        [variation1, variation2].forEach { storageManager.insertSampleProductVariation(readOnlyProductVariation: $0) }
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductVariation.self), 2)

        let orderItems = [
            sampleOrderItem(productID: sampleProductID, variationID: variation1.productVariationID),
            sampleOrderItem(productID: sampleProductID, variationID: variation2.productVariationID)
        ]
        let order = sampleOrder(items: orderItems)

        // When
        var error: Error?
        waitForExpectation(count: 1) { expectation in
            let action = ProductVariationAction.requestMissingVariations(for: order, onCompletion: { anError in
                error = anError
                expectation.fulfill()
            })
            store.onAction(action)
        }

        // Then
        XCTAssertNil(error)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 2)
    }

    func test_requestMissingVariations_returns_error_on_any_variation() throws {
        // Given
        let remote = MockProductVariationsRemote()
        let store = ProductVariationStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let variation1 = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 1)
        let variation2 = MockProductVariation().productVariation(siteID: sampleSiteID, productID: sampleProductID, variationID: 2)
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: variation1.productVariationID,
                                           thenReturn: .success(variation1))
        remote.whenLoadingProductVariation(siteID: sampleSiteID,
                                           productID: sampleProductID,
                                           productVariationID: variation2.productVariationID,
                                           thenReturn: .failure(ProductVariationLoadError.unexpected))

        let orderItems = [
            sampleOrderItem(productID: sampleProductID, variationID: variation1.productVariationID),
            sampleOrderItem(productID: sampleProductID, variationID: variation2.productVariationID)
        ]
        let order = sampleOrder(items: orderItems)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 0)

        // When
        var error: Error?
        waitForExpectation(count: 1) { expectation in
            let action = ProductVariationAction.requestMissingVariations(for: order, onCompletion: { anError in
                error = anError
                expectation.fulfill()
            })
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(error as? ProductVariationLoadError, .requestMissingVariations)
        // The successfully loaded variation should still be saved to storage.
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductVariation.self), 1)
    }
}


private extension ProductVariationStoreTests {
    func sampleProductVariationAttributes() -> [Yosemite.ProductVariationAttribute] {
        return [
            ProductVariationAttribute(id: 0, name: "Darkness", option: "99%"),
            ProductVariationAttribute(id: 0, name: "Flavor", option: "nuts"),
            ProductVariationAttribute(id: 0, name: "Shape", option: "marble")
        ]
    }

    func sampleProductVariation(id: Int64) -> Yosemite.ProductVariation {
        return sampleProductVariation(siteID: sampleSiteID,
                                      productID: sampleProductID,
                                      id: id)
    }

    func sampleProductVariation(siteID: Int64,
                                productID: Int64,
                                id: Int64) -> Yosemite.ProductVariation {
        let imageSource = "https://i0.wp.com/funtestingusa.wpcomstaging.com/wp-content/uploads/2019/11/img_0002-1.jpeg?fit=4288%2C2848&ssl=1"
        return ProductVariation(siteID: siteID,
                                productID: productID,
                                productVariationID: id,
                                attributes: sampleProductVariationAttributes(),
                                image: ProductImage(imageID: 1063,
                                                    dateCreated: dateFromGMT("2019-11-01T04:12:05"),
                                                    dateModified: dateFromGMT("2019-11-01T04:12:05"),
                                                    src: imageSource,
                                                    name: "DSC_0010",
                                                    alt: ""),
                                permalink: "https://chocolate.com/marble",
                                dateCreated: dateFromGMT("2019-11-14T12:40:55"),
                                dateModified: dateFromGMT("2019-11-14T13:06:42"),
                                dateOnSaleStart: dateFromGMT("2019-10-15T21:30:00"),
                                dateOnSaleEnd: dateFromGMT("2019-10-27T21:29:59"),
                                status: .publish,
                                description: "<p>Nutty chocolate marble, 99% and organic.</p>\n",
                                sku: "99%-nuts-marble",
                                price: "12",
                                regularPrice: "12",
                                salePrice: "8",
                                onSale: false,
                                purchasable: true,
                                virtual: false,
                                downloadable: true,
                                downloads: [],
                                downloadLimit: -1,
                                downloadExpiry: 0,
                                taxStatusKey: "taxable",
                                taxClass: "",
                                manageStock: true,
                                stockQuantity: 16,
                                stockStatus: .inStock,
                                backordersKey: "notify",
                                backordersAllowed: true,
                                backordered: false,
                                weight: "2.5",
                                dimensions: ProductDimensions(length: "10",
                                                              width: "2.5",
                                                              height: ""),
                                shippingClass: "",
                                shippingClassID: 0,
                                menuOrder: 8)
    }

    func sampleOrder(items: [Yosemite.OrderItem]) -> Yosemite.Order {
        .init(siteID: sampleSiteID,
              orderID: 963,
              parentID: 0,
              customerID: 11,
              number: "963",
              status: .processing,
              currency: "USD",
              customerNote: "",
              dateCreated: dateFromGMT("2018-04-03T23:05:12"),
              dateModified: dateFromGMT("2018-04-03T23:05:14"),
              datePaid: dateFromGMT("2018-04-03T23:05:14"),
              discountTotal: "30.00",
              discountTax: "1.20",
              shippingTotal: "0.00",
              shippingTax: "0.00",
              total: "31.20",
              totalTax: "1.20",
              paymentMethodID: "stripe",
              paymentMethodTitle: "Credit Card (Stripe)",
              items: items,
              billingAddress: nil,
              shippingAddress: nil,
              shippingLines: [],
              coupons: [],
              refunds: [])
    }

    func sampleOrderItem(productID: Int64, variationID: Int64) -> Yosemite.OrderItem {
        .init(itemID: 890,
              name: "Fruits Basket (Mix & Match Product)",
              productID: productID,
              variationID: variationID,
              quantity: 2,
              price: NSDecimalNumber(integerLiteral: 30),
              sku: "",
              subtotal: "50.00",
              subtotalTax: "2.00",
              taxClass: "",
              taxes: [.init(taxID: 1, subtotal: "2", total: "1.2")],
              total: "30.00",
              totalTax: "1.20",
              attributes: [])
    }

    func dateFromGMT(_ dateStringInGMT: String) -> Date {
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        return dateFormatter.date(from: dateStringInGMT)!
    }
}
