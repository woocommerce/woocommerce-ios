import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ProductStore Unit Tests
///
class ProductStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID = 123

    /// Testing SiteID #2
    ///
    private let sampleSiteID2 = 999

    /// Testing ProductID
    ///
    private let sampleProductID = 282

    /// Testing Variation Type ProductID
    ///
    private let sampleVariationTypeProductID = 295

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
    }


    // MARK: - ProductAction.synchronizeProducts

    /// Verifies that ProductAction.synchronizeProducts effectively persists any retrieved products.
    ///
    func testRetrieveProductsEffectivelyPersistsRetrievedProducts() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 10)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.synchronizeProducts` effectively persists all of the product fields
    /// correctly across all of the related `Product` entities (tags, categories, attributes, etc).
    ///
    func testRetrieveProductsEffectivelyPersistsProductFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct()

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: self.sampleProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)
            XCTAssertEqual(readOnlyStoredProduct, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that ProductAction.synchronizeProducts returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveProductsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve products error response")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "generic_error")
        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that ProductAction.synchronizeProducts returns an error whenever there is no backend response.
    ///
    func testRetrieveProductsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve products empty response")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - ProductAction.retrieveProduct

    /// Verifies that `ProductAction.retrieveProduct` returns the expected `Product`.
    ///
    func testRetrieveSingleProductReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct()

        network.simulateResponse(requestUrlSuffix: "products/282", filename: "product")
        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleProductID) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns the expected `Product` for `variation` product types.
    ///
    func testRetrieveSingleVariationTypeProductReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single variation type product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleVariationTypeProduct()

        network.simulateResponse(requestUrlSuffix: "products/295", filename: "variation-as-product")
        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleVariationTypeProductID) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.retrieveProduct` effectively persists all of the remote product fields
    /// correctly across all of the related `Product` entities (tags, categories, attributes, etc).
    ///
    func testRetrieveSingleProductEffectivelyPersistsProductFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist single product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct()

        network.simulateResponse(requestUrlSuffix: "products/282", filename: "product")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleProductID) { (product, error) in
            XCTAssertNotNil(product)
            XCTAssertNil(error)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: self.sampleProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)
            XCTAssertEqual(readOnlyStoredProduct, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.retrieveProduct` effectively persists all of the remote product fields
    /// correctly across all of the related `Product` entities (tags, categories, attributes, etc) for `variation` product types.
    ///
    func testRetrieveSingleVariationTypeProductEffectivelyPersistsProductFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist single variation type product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleVariationTypeProduct()

        network.simulateResponse(requestUrlSuffix: "products/295", filename: "variation-as-product")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleVariationTypeProductID) { (product, error) in
            XCTAssertNotNil(product)
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: self.sampleVariationTypeProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)
            XCTAssertEqual(readOnlyStoredProduct, remoteProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSingleProductReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve single product error response")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/282", filename: "generic_error")
        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleProductID) { (product, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns an error whenever there is no backend response.
    ///
    func testRetrieveSingleProductReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve single product empty response")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleProductID) { (product, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(product)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that whenever a `ProductAction.retrieveProduct` action results in a response with statusCode = 404, the local entity
    /// is obliterated from existence.
    ///
    func testRetrieveSingleProductResultingInStatusCode404CausesTheStoredProductToGetDeleted() {
        let expectation = self.expectation(description: "Retrieve single product empty response")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        network.simulateError(requestUrlSuffix: "products/282", error: NetworkError.notFound)
        let action = ProductAction.retrieveProduct(siteID: sampleSiteID, productID: sampleProductID) { (product, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(product)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - ProductAction.resetStoredProducts

    /// Verifies that `ProductAction.resetStoredProducts` deletes the Products from Storage
    ///
    func testResetStoredProductsEffectivelyNukesTheProductsCache() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let expectation = self.expectation(description: "Stored Products Reset")
        let action = ProductAction.resetStoredProducts() {
            productStore.upsertStoredProduct(readOnlyProduct: self.sampleProduct(), in: self.viewStorage)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 9)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - ProductStore.upsertStoredProduct

    /// Verifies that `ProductStore.upsertStoredProduct` does not produce duplicate entries.
    ///
    func testUpdateStoredProductEffectivelyUpdatesPreexistantProduct() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProductMutated(), in: viewStorage)
        let storageProduct1 = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        XCTAssertEqual(storageProduct1?.toReadOnly(), sampleProductMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 5)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 1)
    }

    /// Verifies that `ProductStore.upsertStoredProduct` updates the correct site's product.
    ///
    func testUpdateStoredProductEffectivelyUpdatesCorrectSitesProduct() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(sampleSiteID2), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 18)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 4)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 4)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProductMutated(), in: viewStorage)
        let storageProduct1 = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        XCTAssertEqual(storageProduct1?.toReadOnly(), sampleProductMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 14)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 3)

        let storageProduct2 = viewStorage.loadProduct(siteID: sampleSiteID2, productID: sampleProductID)
        XCTAssertEqual(storageProduct2?.toReadOnly(), sampleProduct(sampleSiteID2))
    }

    /// Verifies that `ProductStore.upsertStoredProduct` effectively inserts a new Product, with the specified payload.
    ///
    func testUpdateStoredProductEffectivelyPersistsNewProduct() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct()

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)
        productStore.upsertStoredProduct(readOnlyProduct: remoteProduct, in: viewStorage)

        let storageProduct = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        XCTAssertEqual(storageProduct?.toReadOnly(), remoteProduct)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)
    }

    /// Verifies that Innocuous Upsert OP(s) performed in Derived Contexts **DO NOT** trigger Refresh Events in the
    /// main thread.
    ///
    /// This translates effectively into: Ensure that performing update OP's that don't really change anything, do not
    /// end up causing UI refresh OP's in the main thread.
    ///
    func testInnocuousProductUpdateOperationsPerformedInBackgroundDoNotTriggerUpsertEventsInTheMainThread() {
        // Stack
        let viewContext = storageManager.persistentContainer.viewContext
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let entityListener = EntityListener(viewContext: viewContext, readOnlyEntity: sampleProduct())

        // Track Events: Upsert == 1 / Delete == 0
        var numberOfUpsertEvents = 0
        entityListener.onUpsert = { upserted in
            numberOfUpsertEvents += 1
        }

        // We expect *never* to get a deletion event
        entityListener.onDelete = {
            XCTFail()
        }

        // Initial save: This should trigger *ONE* Upsert event
        let backgroundSaveExpectation = expectation(description: "Retrieve product empty response")
        let derivedContext = storageManager.newDerivedStorage()

        derivedContext.perform {
            productStore.upsertStoredProduct(readOnlyProduct: self.sampleProduct(), in: derivedContext)
        }

        storageManager.saveDerivedType(derivedStorage: derivedContext) {

            // Secondary Save: Expect ZERO new Upsert Events
            derivedContext.perform {
                productStore.upsertStoredProduct(readOnlyProduct: self.sampleProduct(), in: derivedContext)
            }

            self.storageManager.saveDerivedType(derivedStorage: derivedContext) {
                XCTAssertEqual(numberOfUpsertEvents, 1)
                backgroundSaveExpectation.fulfill()
            }
        }

        wait(for: [backgroundSaveExpectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ProductAction.searchProducts

    /// Verifies that `ProductAction.searchProducts` effectively persists the retrieved products.
    ///
    func testSearchProductsEffectivelyPersistsRetrievedSearchProducts() {
        let expectation = self.expectation(description: "Search Products")
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // A product that is expected to be in the search results.
        let expectedProductID = 67
        let expectedProductName = "Photo"

        let keyword = "photo"
        let action = ProductAction.searchProducts(siteID: sampleSiteID,
                                                  keyword: keyword,
                                                  pageNumber: defaultPageNumber,
                                                  pageSize: defaultPageSize,
                                                  onCompletion: { [weak self] error in
                                                    guard let self = self else {
                                                        XCTFail()
                                                        return
                                                    }

                                                    let expectedProduct = self.viewStorage
                                                        .loadProduct(siteID: self.sampleSiteID,
                                                                     productID: expectedProductID)?.toReadOnly()
                                                    XCTAssertEqual(expectedProduct?.name, expectedProductName)

                                                    XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 2)

                                                    XCTAssertNil(error)

                                                    expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.searchProducts` effectively upserts the `ProductSearchResults` entity.
    ///
    func testSearchProductsEffectivelyPersistsSearchResultsEntity() {
        let expectation = self.expectation(description: "Search Products")
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let keyword = "hiii"
        let anotherKeyword = "hello"
        let action = ProductAction.searchProducts(siteID: sampleSiteID,
                                                  keyword: keyword,
                                                  pageNumber: defaultPageNumber,
                                                  pageSize: defaultPageSize,
                                                  onCompletion: { [weak self] error in
                                                    guard let self = self else {
                                                        XCTFail()
                                                        return
                                                    }

                                                    XCTAssertNil(error)

                                                    let searchResults = self.viewStorage.loadProductSearchResults(keyword: keyword)
                                                    XCTAssertEqual(searchResults?.keyword, keyword)
                                                    XCTAssertEqual(searchResults?.products?.count, self.viewStorage.countObjects(ofType: Storage.Product.self))

                                                    let searchResultsWithAnotherKeyword = self.viewStorage.loadProductSearchResults(keyword: anotherKeyword)
                                                    XCTAssertNil(searchResultsWithAnotherKeyword)

                                                    expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.searchProducts` does not result in duplicated entries in the ProductSearchResults entity.
    ///
    func testSearchProductsDoesNotProduceDuplicatedReferences() {
        let expectation = self.expectation(description: "Search Products")
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let keyword = "hiii"
        let nestedAction = ProductAction
            .searchProducts(siteID: sampleSiteID,
                            keyword: keyword,
                            pageNumber: defaultPageNumber,
                            pageSize: defaultPageSize,
                            onCompletion: { [weak self] error in
                                guard let self = self else {
                                    XCTFail()
                                    return
                                }
                                let products = self.viewStorage.allObjects(ofType: Storage.Product.self, matching: nil, sortedBy: nil)
                                XCTAssertEqual(products.count, 10)
                                for product in products {
                                    XCTAssertEqual(product.searchResults?.count, 1)
                                    XCTAssertEqual(product.searchResults?.first?.keyword, keyword)
                                }

                                let searchResults = self.viewStorage.allObjects(ofType: Storage.ProductSearchResults.self, matching: nil, sortedBy: nil)
                                XCTAssertEqual(searchResults.count, 1)
                                XCTAssertEqual(searchResults.first?.products?.count, 10)
                                XCTAssertEqual(searchResults.first?.keyword, keyword)

                                XCTAssertNil(error)

                                expectation.fulfill()
            })

        let firstAction = ProductAction.searchProducts(siteID: sampleSiteID,
                                                       keyword: keyword,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       onCompletion: { error in
                                                        store.onAction(nestedAction)
        })

        store.onAction(firstAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ProductAction.updateProduct

    /// Verifies that `ProductAction.updateProduct` returns the expected `Product`.
    ///
    func testUpdatingProductReturnsExpectedFields() {
        let expectation = self.expectation(description: "Update product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let expectedProductID = 847
        let expectedProductName = "This is my new product name!"
        let expectedProductDescription = "Learn something!"

        network.simulateResponse(requestUrlSuffix: "products/\(expectedProductID)", filename: "product-update")
        let product = sampleProduct(productID: expectedProductID)
        let action = ProductAction.updateProduct(product: product) { (product, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(product)
            XCTAssertEqual(product?.productID, expectedProductID)
            XCTAssertEqual(product?.name, expectedProductName)
            XCTAssertEqual(product?.fullDescription, expectedProductDescription)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: expectedProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)
            XCTAssertEqual(readOnlyStoredProduct?.productID, expectedProductID)
            XCTAssertEqual(readOnlyStoredProduct?.name, expectedProductName)
            XCTAssertEqual(readOnlyStoredProduct?.fullDescription, expectedProductDescription)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.updateProduct` effectively persists all of the remote product fields
    /// correctly across all of the related `Product` entities (tags, categories, attributes, etc) for `variation` product types.
    ///
    func testUpdatingProductEffectivelyPersistsRelatedObjects() {
        let expectation = self.expectation(description: "Update product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let expectedProductID = 847

        network.simulateResponse(requestUrlSuffix: "products/\(expectedProductID)", filename: "product-update")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let product = sampleProduct(productID: expectedProductID)
        let action = ProductAction.updateProduct(product: product) { (product, error) in
            XCTAssertNotNil(product)
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 2)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 5)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: expectedProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.updateProduct` returns an error whenever there is an error response from the backend.
    ///
    func testUpdatingProductReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Update product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "generic_error")
        let product = sampleProduct()
        let action = ProductAction.updateProduct(product: product) { (product, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.updateProduct` returns an error whenever there is no backend response.
    ///
    func testUpdatingProductReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Update product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let product = sampleProduct()
        let action = ProductAction.updateProduct(product: product) { (product, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(product)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that whenever a `ProductAction.updateProduct` action results in a response with statusCode = 404, the local entity is not deleted.
    ///
    func testUpdatingProductResultingInStatusCode404DoesNotCauseTheStoredProductToGetDeleted() {
        let expectation = self.expectation(description: "Update product")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        network.simulateError(requestUrlSuffix: "products/\(sampleProductID)", error: NetworkError.notFound)
        let product = sampleProduct()
        let action = ProductAction.updateProduct(product: product) { (product, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(product)
            // The existing Product should not be deleted on 404 response.
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

// MARK: - Private Helpers
//
private extension ProductStoreTests {

    func sampleProduct(_ siteID: Int? = nil, productID: Int? = nil) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID
        let testProductID = productID ?? sampleProductID
        return Product(siteID: testSiteID,
                       productID: testProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "",
                       price: "0",
                       regularPrice: "",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: true,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: false,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       dimensions: sampleDimensions(),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: sampleCategories(),
                       tags: sampleTags(),
                       images: sampleImages(),
                       attributes: sampleAttributes(),
                       defaultAttributes: sampleDefaultAttributes(),
                       variations: [192, 194, 193],
                       groupedProducts: [],
                       menuOrder: 0)
    }

    func sampleDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "12", width: "33", height: "54")
    }

    func sampleCategories() -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, name: "Events", slug: "events")
        return [category1]
    }

    func sampleTags() -> [Networking.ProductTag] {
        let tag1 = ProductTag(tagID: 37, name: "room", slug: "room")
        let tag2 = ProductTag(tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(tagID: 39, name: "30", slug: "30")
        let tag4 = ProductTag(tagID: 40, name: "20+", slug: "20")
        let tag5 = ProductTag(tagID: 41, name: "meeting room", slug: "meeting-room")
        let tag6 = ProductTag(tagID: 42, name: "meetings", slug: "meetings")
        let tag7 = ProductTag(tagID: 43, name: "parties", slug: "parties")
        let tag8 = ProductTag(tagID: 44, name: "graduation", slug: "graduation")
        let tag9 = ProductTag(tagID: 45, name: "birthday party", slug: "birthday-party")

        return [tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9]
    }

    func sampleImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: date(with: "2018-01-26T21:49:45"),
                                  dateModified: date(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        return [image1]
    }

    func sampleAttributes() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 1,
                                          visible: true,
                                          variation: true,
                                          options: ["Purple", "Yellow", "Hot Pink", "Lime Green", "Teal"])

        let attribute2 = ProductAttribute(attributeID: 0,
                                          name: "Size",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Small", "Medium", "Large"])

        return [attribute1, attribute2]
    }

    func sampleDefaultAttributes() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")
        let defaultAttribute2 = ProductDefaultAttribute(attributeID: 0, name: "Size", option: "Medium")

        return [defaultAttribute1, defaultAttribute2]
    }

    func sampleDownloads() -> [Networking.ProductDownload] {
        let download1 = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                        name: "Song #1",
                                        fileURL: "https://woocommerce.files.wordpress.com/2017/06/woo-single-1.ogg")
        let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                        name: "Artwork",
                                        fileURL: "https://thuy-test.mystagingwebsite.com/wp-content/uploads/2018/01/cd_4_angle.jpg")
        let download3 = ProductDownload(downloadID: "240cd543-5457-498e-95e2-6b51fdaf15cc",
                                        name: "Artwork 2",
                                        fileURL: "https://thuy-test.mystagingwebsite.com/wp-content/uploads/2018/01/cd_4_flat.jpg")
        return [download1, download2, download3]
    }

    func sampleProductMutated(_ siteID: Int? = nil) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID

        return Product(siteID: testSiteID,
                       productID: sampleProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "345",
                       price: "123",
                       regularPrice: "",
                       salePrice: "",
                       onSale: true,
                       purchasable: false,
                       totalSales: 66,
                       virtual: false,
                       downloadable: true,
                       downloads: sampleDownloads(),
                       downloadLimit: 1,
                       downloadExpiry: 1,
                       externalURL: "http://somewhere.com.net",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: true,
                       stockQuantity: nil,
                       stockStatusKey: "nostock",
                       backordersKey: "yes",
                       backordersAllowed: true,
                       backordered: true,
                       soldIndividually: false,
                       weight: "777",
                       dimensions: sampleDimensionsMutated(),
                       shippingRequired: true,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: false,
                       averageRating: "1.30",
                       ratingCount: 76,
                       relatedIDs: [31, 22, 369],
                       upsellIDs: [99, 123, 234, 444],
                       crossSellIDs: [1234, 234234, 999, 989],
                       parentID: 444,
                       purchaseNote: "Whatever!",
                       categories: sampleCategoriesMutated(),
                       tags: sampleTagsMutated(),
                       images: sampleImagesMutated(),
                       attributes: sampleAttributesMutated(),
                       defaultAttributes: sampleDefaultAttributesMutated(),
                       variations: [],
                       groupedProducts: [111, 222, 333],
                       menuOrder: 0)
    }

    func sampleDimensionsMutated() -> Networking.ProductDimensions {
        return ProductDimensions(length: "12", width: "33", height: "54")
    }

    func sampleCategoriesMutated() -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, name: "Events", slug: "events")
        let category2 = ProductCategory(categoryID: 362, name: "Other Stuff", slug: "other")
        return [category1, category2]
    }

    func sampleTagsMutated() -> [Networking.ProductTag] {
        let tag1 = ProductTag(tagID: 37, name: "something", slug: "something")
        let tag2 = ProductTag(tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(tagID: 39, name: "3000", slug: "3000")
        let tag4 = ProductTag(tagID: 45, name: "birthday party", slug: "birthday-party")
        let tag5 = ProductTag(tagID: 95, name: "yep", slug: "yep")

        return [tag1, tag2, tag3, tag4, tag5]
    }

    func sampleImagesMutated() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: date(with: "2018-01-26T21:49:45"),
                                  dateModified: date(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        let image2 = ProductImage(imageID: 999,
                                  dateCreated: date(with: "2019-01-26T21:44:45"),
                                  dateModified: date(with: "2019-01-26T21:54:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/test.png",
                                  name: "ZZZTest Image",
                                  alt: "")
        return [image1, image2]
    }

    func sampleAttributesMutated() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 0,
                                          visible: false,
                                          variation: false,
                                          options: ["Purple", "Yellow"])

        return [attribute1]
    }

    func sampleDefaultAttributesMutated() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")

        return [defaultAttribute1]
    }

    func sampleVariationTypeProduct(_ siteID: Int? = nil) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID
        return Product(siteID: testSiteID,
                       productID: sampleVariationTypeProductID,
                       name: "Paper Airplane - Black, Long",
                       slug: "paper-airplane-3",
                       permalink: "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Long",
                       dateCreated: date(with: "2019-04-04T22:06:45"),
                       dateModified: date(with: "2019-04-09T20:24:03"),
                       productTypeKey: "variation",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>Long paper airplane. Color is black. </p>\n",
                       briefDescription: "",
                       sku: "345345-2",
                       price: "22.72",
                       regularPrice: "22.72",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: false,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: true,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "888",
                       dimensions: sampleVariationTypeDimensions(),
                       shippingRequired: true,
                       shippingTaxable: true,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: true,
                       averageRating: "0.00",
                       ratingCount: 0,
                       relatedIDs: [],
                       upsellIDs: [],
                       crossSellIDs: [],
                       parentID: 205,
                       purchaseNote: "",
                       categories: [],
                       tags: [],
                       images: sampleVariationTypeImages(),
                       attributes: sampleVariationTypeAttributes(),
                       defaultAttributes: [],
                       variations: [],
                       groupedProducts: [],
                       menuOrder: 2)
    }

    func sampleVariationTypeDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "11", width: "22", height: "33")
    }

    func sampleVariationTypeImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 301,
                                  dateCreated: date(with: "2019-04-09T20:23:58"),
                                  dateModified: date(with: "2019-04-09T20:23:58"),
                                  src: "https://i0.wp.com/paperairplane.store/wp-content/uploads/2019/04/paper_plane_black.png?fit=600%2C473&ssl=1",
                                  name: "paper_plane_black",
                                  alt: "")
        return [image1]
    }

    func sampleVariationTypeAttributes() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Black"])

        let attribute2 = ProductAttribute(attributeID: 0,
                                          name: "Length",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Long"])

        return [attribute1, attribute2]
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
