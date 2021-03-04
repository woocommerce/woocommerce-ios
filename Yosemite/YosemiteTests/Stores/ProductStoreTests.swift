import XCTest
import TestKit
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ProductStore Unit Tests
///
final class ProductStoreTests: XCTestCase {

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

    /// Testing SiteID #2
    ///
    private let sampleSiteID2: Int64 = 999

    /// Testing ProductID
    ///
    private let sampleProductID: Int64 = 282

    /// Testing Variation Type ProductID
    ///
    private let sampleVariationTypeProductID: Int64 = 295

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
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - ProductAction.addProduct

    func test_addProduct_returns_the_expected_product_with_related_objects() throws {
        // Arrange
        let remote = MockProductsRemote()
        let mockImage = ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        let mockTag = ProductTag(siteID: 123, tagID: 1, name: "", slug: "")
        let mockDefaultAttribute = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")
        let mockAttribute = ProductAttribute(siteID: sampleSiteID,
                                             attributeID: 0,
                                             name: "Brand",
                                             position: 1,
                                             visible: true,
                                             variation: true,
                                             options: ["Unknown", "House"])
        let mockCategory = ProductCategory(categoryID: 36, siteID: 2, parentID: 1, name: "Events", slug: "events")
        let expectedProduct = MockProduct().product().copy(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           downloads: sampleDownloads(),
                                                           dimensions: ProductDimensions(length: "12", width: "26", height: "16"),
                                                           shippingClass: "2-day",
                                                           shippingClassID: 1,
                                                           categories: [mockCategory],
                                                           tags: [mockTag],
                                                           images: [mockImage],
                                                           attributes: [mockAttribute],
                                                           defaultAttributes: [mockDefaultAttribute])
        remote.whenAddingProduct(siteID: sampleSiteID, thenReturn: .success(expectedProduct))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        let product = MockProduct().product(siteID: sampleSiteID, productID: 0)

        var result: Result<Yosemite.Product, ProductUpdateError>?
        waitForExpectation { expectation in
            let action = ProductAction.addProduct(product: product) { aResult in
                result = aResult
                expectation.fulfill()
            }
            productStore.onAction(action)
        }

        // Assert
        let addedProduct = try XCTUnwrap(result?.get())
        XCTAssertEqual(addedProduct, expectedProduct)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDownload.self), 3)
    }

    func test_addProduct_returns_error_upon_network_error() {
        // Arrange
        let remote = MockProductsRemote()
        remote.whenAddingProduct(siteID: sampleSiteID, thenReturn: .failure(DotcomError.requestFailed))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        let product = MockProduct().product(siteID: sampleSiteID, productID: 0)

        var result: Result<Yosemite.Product, ProductUpdateError>?
        waitForExpectation { expectation in
            let action = ProductAction.addProduct(product: product) { aResult in
                result = aResult
                expectation.fulfill()
            }
            productStore.onAction(action)
        }

        // Assert
        XCTAssertEqual(result?.isFailure, true)
    }

    // MARK: - ProductAction.deleteProduct

    func test_deleteProduct_deletes_the_stored_product() throws {
        // Arrange
        let remote = MockProductsRemote()
        let mockImage = ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        let mockTag = ProductTag(siteID: 123, tagID: 1, name: "", slug: "")
        let mockDefaultAttribute = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")
        let mockAttribute = ProductAttribute(siteID: sampleSiteID,
                                             attributeID: 0,
                                             name: "Brand",
                                             position: 1,
                                             visible: true,
                                             variation: true,
                                             options: ["Unknown", "House"])
        let mockCategory = ProductCategory(categoryID: 36, siteID: 2, parentID: 1, name: "Events", slug: "events")
        let expectedProduct = MockProduct().product().copy(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           dimensions: ProductDimensions(length: "12", width: "26", height: "16"),
                                                           shippingClass: "2-day",
                                                           shippingClassID: 1,
                                                           categories: [mockCategory],
                                                           tags: [mockTag],
                                                           images: [mockImage],
                                                           attributes: [mockAttribute],
                                                           defaultAttributes: [mockDefaultAttribute])
        remote.whenDeletingProduct(siteID: sampleSiteID, thenReturn: .success(expectedProduct))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        productStore.upsertStoredProduct(readOnlyProduct: expectedProduct, in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        var result: Result<Yosemite.Product, ProductUpdateError>?
        waitForExpectation { expectation in
            let action = ProductAction.deleteProduct(siteID: sampleSiteID, productID: sampleProductID) { (aResult) in
                result = aResult
                expectation.fulfill()
            }
            productStore.onAction(action)
        }

        // Assert
        let deletedProduct = try XCTUnwrap(result?.get())
        XCTAssertEqual(deletedProduct, expectedProduct)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)
    }

    func test_deleteProduct_returns_error_upon_network_error() {
        // Arrange
        let remote = MockProductsRemote()
        remote.whenDeletingProduct(siteID: sampleSiteID, thenReturn: .failure(DotcomError.requestFailed))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        var result: Result<Yosemite.Product, ProductUpdateError>?
        waitForExpectation { expectation in
            let action = ProductAction.deleteProduct(siteID: sampleSiteID, productID: sampleProductID) { (aResult) in
                result = aResult
                expectation.fulfill()
            }
            productStore.onAction(action)
        }

        // Assert
        XCTAssertEqual(result?.isFailure, true)
    }

    // MARK: - ProductAction.synchronizeProducts

    /// Verifies that ProductAction.synchronizeProducts effectively persists any retrieved products.
    ///
    func testRetrieveProductsEffectivelyPersistsRetrievedProducts() {
        let expectation = self.expectation(description: "Retrieve product list")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
                                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 10)
                                                        XCTAssertTrue(result.isSuccess)
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

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
            XCTAssertTrue(result.isSuccess)

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

    func testsRetrieveProductsDontNilStoredProductCategoryParentId() {
        // Given an initial store category and simulated product response
        let expectation = self.expectation(description: #function)
        let initialCategory = sampleCategories(parentID: 17)[0]
        storageManager.insertSampleProductCategory(readOnlyProductCategory: initialCategory)

        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        // When a `synchronizeProducts` action is dispatched
        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { error in
            expectation.fulfill()
        }
        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then the initially stored category should preserve it's `parentID`
        let storedCategory = viewStorage.loadProductCategory(siteID: sampleSiteID, categoryID: initialCategory.categoryID)
        XCTAssertEqual(storedCategory?.parentID, initialCategory.parentID)
    }

    /// Verifies that ProductAction.synchronizeProducts for the first page deletes stored Products for the given site ID.
    ///
    func testSyncingProductsOnTheFirstPageResetsStoredProducts() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Upserts some Products into the storage with two site IDs.
        let siteID1: Int64 = 134
        let siteID2: Int64 = 591

        let productID: Int64 = 123
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(siteID1, productID: productID), in: viewStorage)
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(siteID2, productID: productID), in: viewStorage)

        let expectation = self.expectation(description: "Persist product list")

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 2)

        let action = ProductAction.synchronizeProducts(siteID: siteID1,
                                                       pageNumber: ProductStore.Default.firstPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
            XCTAssertTrue(result.isSuccess)

            // The previously upserted Product for siteID1 should be deleted.
            let storedProductForSite1 = self.viewStorage.loadProduct(siteID: siteID1, productID: productID)
            XCTAssertNil(storedProductForSite1)

            // The previously upserted Product for siteID2 should stay in storage.
            let storedProductForSite2 = self.viewStorage.loadProduct(siteID: siteID2, productID: productID)
            XCTAssertNotNil(storedProductForSite2)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that ProductAction.synchronizeProducts after the first page does not delete stored Products for the given
    /// site ID.
    ///
    func testSyncingProductsAfterTheFirstPage() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Upserts some Products into the storage.
        let siteID: Int64 = 134

        // This product ID should not exist in the network response.
        let productID: Int64 = 888
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(siteID, productID: productID), in: viewStorage)

        let expectation = self.expectation(description: "Persist product list")

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        let action = ProductAction.synchronizeProducts(siteID: siteID,
                                                       pageNumber: 3,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
            XCTAssertTrue(result.isSuccess)

            // The previously upserted Product's should stay in storage.
            let storedProductForSite1 = self.viewStorage.loadProduct(siteID: siteID, productID: productID)
            XCTAssertNotNil(storedProductForSite1)

            XCTAssertGreaterThan(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that ProductAction.synchronizeProducts for the first page does not delete stored Products if the API call fails.
    ///
    func testSyncingProductsOnTheFirstPageDoesNotDeleteStoredProductsUponResponseError() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Upserts some Products into the storage.
        let siteID: Int64 = 134

        // This product ID should not exist in the network response.
        let productID: Int64 = 888
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(siteID, productID: productID), in: viewStorage)

        let expectation = self.expectation(description: "Retrieve products error response")

        network.simulateResponse(requestUrlSuffix: "products", filename: "generic_error")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        let action = ProductAction.synchronizeProducts(siteID: siteID,
                                                       pageNumber: ProductStore.Default.firstPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
            XCTAssertTrue(result.isFailure)

            // The previously upserted Product's should stay in storage.
            let storedProductForSite1 = self.viewStorage.loadProduct(siteID: siteID, productID: productID)
            XCTAssertNotNil(storedProductForSite1)

            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_synchronizing_products_of_the_same_page_size_has_next_page() {
        // Arrange
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        // Action
        var result: Result<Bool, Error>?
        waitForExpectation { expectation in
            let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                           pageNumber: 1,
                                                           pageSize: 10, // This matches the response size in `products-load-all.json`
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           sortOrder: .nameAscending) { aResult in
                result = aResult
                expectation.fulfill()
            }
            store.onAction(action)
        }

        // Assert
        XCTAssertTrue(try XCTUnwrap(result).get())
    }

    func test_synchronizing_products_of_smaller_size_than_page_size_has_no_next_page() {
        // Arrange
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        // Action
        var result: Result<Bool, Error>?
        waitForExpectation { expectation in
            let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                           pageNumber: 1,
                                                           pageSize: 20, // This must be larger than the response size in `products-load-all.json`
                                                           stockStatus: nil,
                                                           productStatus: nil,
                                                           productType: nil,
                                                           sortOrder: .nameAscending) { aResult in
                result = aResult
                expectation.fulfill()
            }
            store.onAction(action)
        }

        // Assert
        XCTAssertFalse(try XCTUnwrap(result).get())
    }

    /// Verifies that ProductAction.synchronizeProducts returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveProductsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve products error response")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "generic_error")
        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
            XCTAssertTrue(result.isFailure)
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

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       sortOrder: .nameAscending) { result in
            XCTAssertTrue(result.isFailure)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - ProductAction.retrieveProduct

    /// Verifies that `ProductAction.retrieveProduct` returns the expected `Product`.
    ///
    func testRetrieveSingleProductReturnsExpectedFields() throws {
        // Arrange
        // The shipping class ID should match the `shipping_class_id` field in `product.json`.
        let expectedShippingClass = sampleProductShippingClass(remoteID: 134, siteID: sampleSiteID)
        storageManager.insertSampleProductShippingClass(readOnlyProductShippingClass: expectedShippingClass)

        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct(productShippingClass: expectedShippingClass, downloadable: true)

        // Action
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product")
        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        let product = try XCTUnwrap(result.get())
        XCTAssertEqual(product, remoteProduct)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns the expected `Product` of external product type.
    ///
    func testRetrieveSingleExternalProductReturnsExpectedFields() throws {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProduct = MockProduct().product(siteID: sampleSiteID, productID: sampleProductID, buttonText: "Deal", externalURL: "https://example.com")
        remote.whenLoadingProduct(siteID: sampleSiteID, productID: sampleProductID, thenReturn: .success(expectedProduct))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        let product = try XCTUnwrap(result.get())
        XCTAssertEqual(product, expectedProduct)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns the expected `Product` for `variation` product types.
    ///
    func testRetrieveSingleVariationTypeProductReturnsExpectedFields() throws {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleVariationTypeProduct()

        // Action
        network.simulateResponse(requestUrlSuffix: "products/295", filename: "variation-as-product")
        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleVariationTypeProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        let product = try XCTUnwrap(result.get())
        XCTAssertEqual(product, remoteProduct)
    }

    /// Verifies that `ProductAction.retrieveProduct` effectively persists all of the remote product fields
    /// correctly across all of the related `Product` entities (tags, categories, attributes, etc).
    ///
    func testRetrieveSingleProductEffectivelyPersistsProductFieldsAndRelatedObjects() throws {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // The shipping class ID should match the `shipping_class_id` field in `product.json`.
        let expectedShippingClass = sampleProductShippingClass(remoteID: 134, siteID: sampleSiteID)
        storageManager.insertSampleProductShippingClass(readOnlyProductShippingClass: expectedShippingClass)

        let remoteProduct = sampleProduct(productShippingClass: expectedShippingClass, downloadable: true)

        // Action
        network.simulateResponse(requestUrlSuffix: "products/282", filename: "product")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        XCTAssertTrue(result.isSuccess)

        let storedProduct = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        let readOnlyStoredProduct = storedProduct?.toReadOnly()
        XCTAssertNotNil(storedProduct)
        XCTAssertNotNil(readOnlyStoredProduct)
        XCTAssertEqual(readOnlyStoredProduct, remoteProduct)
    }

    /// Verifies that `ProductAction.retrieveProduct` effectively persists all of the remote product fields
    /// correctly across all of the related `Product` entities (tags, categories, attributes, etc) for `variation` product types.
    ///
    func testRetrieveSingleVariationTypeProductEffectivelyPersistsProductFieldsAndRelatedObjects() throws {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleVariationTypeProduct()

        // Action
        network.simulateResponse(requestUrlSuffix: "products/295", filename: "variation-as-product")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleVariationTypeProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)

        let storedProduct = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleVariationTypeProductID)
        let readOnlyStoredProduct = storedProduct?.toReadOnly()
        XCTAssertNotNil(storedProduct)
        XCTAssertNotNil(readOnlyStoredProduct)
        XCTAssertEqual(readOnlyStoredProduct, remoteProduct)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSingleProductReturnsErrorUponReponseError() throws {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Action
        network.simulateResponse(requestUrlSuffix: "products/282", filename: "generic_error")
        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        XCTAssertNotNil(result.failure)
    }

    /// Verifies that `ProductAction.retrieveProduct` returns an error whenever there is no backend response.
    ///
    func testRetrieveSingleProductReturnsErrorUponEmptyResponse() throws {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Action
        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        XCTAssertNotNil(result.failure)
    }

    /// Verifies that whenever a `ProductAction.retrieveProduct` action results in a response with statusCode = 404, the local entity
    /// is obliterated from existence.
    ///
    func testRetrieveSingleProductResultingInStatusCode404CausesTheStoredProductToGetDeleted() throws {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        let dotComError = DotcomError.unknown(code: ProductLoadError.ErrorCode.invalidID.rawValue, message: nil)

        // Action
        network.simulateError(requestUrlSuffix: "products/282", error: dotComError)
        let result: Result<Yosemite.Product, Error> = waitFor { promise in
            let action = ProductAction.retrieveProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Assert
        let error = try XCTUnwrap(result.failure as? ProductLoadError)
        XCTAssertEqual(error, ProductLoadError.notFound)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
    }


    // MARK: - ProductAction.resetStoredProducts

    /// Verifies that `ProductAction.resetStoredProducts` deletes the Products from Storage
    ///
    func testResetStoredProductsEffectivelyNukesTheProductsCache() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let expectation = self.expectation(description: "Stored Products Reset")
        let action = ProductAction.resetStoredProducts() {
            productStore.upsertStoredProduct(readOnlyProduct: self.sampleProduct(downloadable: true), in: self.viewStorage)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 9)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDownload.self), 3)

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
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDownload.self), 0)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(downloadable: true), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID)), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDownload.self), 3)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProductMutated(), in: viewStorage)
        let storageProduct1 = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        XCTAssertEqual(storageProduct1?.toReadOnly(), sampleProductMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID)), 10)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDownload.self), 2)
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
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID)), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(sampleSiteID2), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID2)), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 4)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 4)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProductMutated(), in: viewStorage)
        let storageProduct1 = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        XCTAssertEqual(storageProduct1?.toReadOnly(), sampleProductMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID)), 10)
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
        let remoteProduct = sampleProduct(downloadable: true)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDownload.self), 0)
        productStore.upsertStoredProduct(readOnlyProduct: remoteProduct, in: viewStorage)

        let storageProduct = viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)
        XCTAssertEqual(storageProduct?.toReadOnly(), remoteProduct)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID)), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDownload.self), 3)
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

        // Track Events: Upsert == 2 / Delete == 0
        var numberOfUpsertEvents = 0
        entityListener.onUpsert = { upserted in
            numberOfUpsertEvents += 1
        }

        // We expect *never* to get a deletion event
        entityListener.onDelete = {
            XCTFail()
        }

        // Initial save: This should trigger two Upsert events:
        // first one for the first Product upsert, and the second one for the Product image upsert.
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
                XCTAssertEqual(numberOfUpsertEvents, 2)
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
        let expectedProductID: Int64 = 67
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

        let expectedProductID: Int64 = 847
        let expectedProductName = "This is my new product name!"
        let expectedProductDescription = "Learn something!"
        let expectedProductShippingClassID: Int64 = 96987515
        let expectedProductShippingClassSlug = "two-days"
        let expectedProductShippingClass = sampleProductShippingClass(remoteID: expectedProductShippingClassID, siteID: sampleSiteID)
        let expectedProductSKU = "94115"
        let expectedProductManageStock = true
        let expectedProductSoldIndividually = false
        let expectedStockQuantity: Decimal = 99
        let expectedBackordersSetting = ProductBackordersSetting.allowed
        let expectedStockStatus = ProductStockStatus.inStock
        let expectedProductRegularPrice = "12.00"
        let expectedProductSalePrice = "10.00"
        let expectedProductSaleStart = date(with: "2019-10-15T21:30:11")
        let expectedProductSaleEnd = date(with: "2019-10-27T21:29:50")
        let expectedProductTaxStatus = "taxable"
        let expectedProductTaxClass = "reduced-rate"
        let expectedDownloadableFileCount = 0
        let expectedDownloadable = false

        network.simulateResponse(requestUrlSuffix: "products/\(expectedProductID)", filename: "product-update")
        let product = sampleProduct(productID: expectedProductID)

        // Saves an existing shipping class into storage, so that it can be linked to the updated product.
        // The shipping class ID should match the `shipping_class_id` field in `product.json`.
        storageManager.insertSampleProductShippingClass(readOnlyProductShippingClass: expectedProductShippingClass)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductShippingClass.self), 1)

        // Saves an existing Product into storage.
        // Note: the fields to be tested should be different in the sample model and network response.
        storageManager.insertSampleProduct(readOnlyProduct: product)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 1)

        let action = ProductAction.updateProduct(product: product) { result in
            guard case let .success(product) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertEqual(product.productID, expectedProductID)
            XCTAssertEqual(product.name, expectedProductName)
            XCTAssertEqual(product.fullDescription, expectedProductDescription)
            // Shipping settings.
            XCTAssertEqual(product.shippingClassID, expectedProductShippingClassID)
            XCTAssertEqual(product.shippingClass, expectedProductShippingClassSlug)
            XCTAssertEqual(product.productShippingClass, expectedProductShippingClass)
            // Inventory settings.
            XCTAssertEqual(product.sku, expectedProductSKU)
            XCTAssertEqual(product.manageStock, expectedProductManageStock)
            XCTAssertEqual(product.soldIndividually, expectedProductSoldIndividually)
            XCTAssertEqual(product.stockQuantity, expectedStockQuantity)
            XCTAssertEqual(product.backordersSetting, expectedBackordersSetting)
            XCTAssertEqual(product.productStockStatus, expectedStockStatus)
            // Price settings.
            XCTAssertEqual(product.regularPrice, expectedProductRegularPrice)
            XCTAssertEqual(product.salePrice, expectedProductSalePrice)
            XCTAssertEqual(product.dateOnSaleStart, expectedProductSaleStart)
            XCTAssertEqual(product.dateOnSaleEnd, expectedProductSaleEnd)
            XCTAssertEqual(product.taxStatusKey, expectedProductTaxStatus)
            XCTAssertEqual(product.taxClass, expectedProductTaxClass)
            XCTAssertEqual(product.downloadable, expectedDownloadable)
            XCTAssertEqual(product.downloads.count, expectedDownloadableFileCount)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: expectedProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)
            XCTAssertEqual(readOnlyStoredProduct, product)

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

        let expectedProductID: Int64 = 847

        network.simulateResponse(requestUrlSuffix: "products/\(expectedProductID)", filename: "product-update")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // Inserts the expected shipping class model.
        let existingShippingClass = ProductShippingClass(count: 2020,
                                                         descriptionHTML: "Arriving in 2 days!",
                                                         name: "2 Days",
                                                         shippingClassID: 96987515,
                                                         siteID: sampleSiteID,
                                                         slug: "2-days")
        let existingStorageShippingClass = viewStorage.insertNewObject(ofType: StorageProductShippingClass.self)
        existingStorageShippingClass.update(with: existingShippingClass)

        let product = sampleProduct(productID: expectedProductID, downloadable: true)
        let action = ProductAction.updateProduct(product: product) { result in
            guard case .success = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductTag.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCategory.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductImage.self), 2)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 5)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductDownload.self), 0)

            let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: expectedProductID)
            let readOnlyStoredProduct = storedProduct?.toReadOnly()
            XCTAssertNotNil(storedProduct)
            XCTAssertNotNil(readOnlyStoredProduct)

            // Asserts updated relationships.
            XCTAssertEqual(readOnlyStoredProduct?.productShippingClass, existingShippingClass)

            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductAction.updateProduct` returns an error whenever there is an error response from the backend.
    ///
    func testUpdatingProductReturnsErrorUponReponseError() {
        // Given
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "generic_error")

        // When
        let product = sampleProduct()
        waitForExpectation { expectation in
            let action = ProductAction.updateProduct(product: product) { result in
                // Then
                guard case .failure = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                expectation.fulfill()
            }
            productStore.onAction(action)
        }
    }

    /// Verifies that `ProductAction.updateProduct` returns an error whenever there is no backend response.
    ///
    func testUpdatingProductReturnsErrorUponEmptyResponse() {
        // Given
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let product = sampleProduct()
        waitForExpectation { expectation in
            let action = ProductAction.updateProduct(product: product) { result in
                // Then
                guard case .failure = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                expectation.fulfill()
            }
            productStore.onAction(action)
        }
    }

    /// Verifies that whenever a `ProductAction.updateProduct` action results in a response with statusCode = 404, the local entity is not deleted.
    ///
    func testUpdatingProductResultingInStatusCode404DoesNotCauseTheStoredProductToGetDeleted() {
        // Given
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        network.simulateError(requestUrlSuffix: "products/\(sampleProductID)", error: NetworkError.notFound)

        // When
        let product = sampleProduct()
        waitForExpectation { expectation in
            let action = ProductAction.updateProduct(product: product) { result in
                // Then
                guard case .failure = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                // The existing Product should not be deleted on 404 response.
                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 1)

                expectation.fulfill()
            }
            productStore.onAction(action)
        }
    }

    /// Verifies that whenever a `ProductAction.updateProduct` action results in product update maintaint the Product Tags order.
    ///
    func testUpdatingProductResultingMantainingTheSameOrderForTags() {
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let product = sampleProduct(sampleSiteID, productID: sampleProductID)
        productStore.upsertStoredProduct(readOnlyProduct: product, in: viewStorage)
        let productStored = viewStorage.loadProduct(siteID: self.sampleSiteID, productID: self.sampleProductID)

        XCTAssertEqual(product.tags.map { $0.tagID }, productStored?.tagsArray.map { $0.tagID })

        let productMutated = sampleProduct(sampleSiteID,
                                           productID: sampleProductID,
                                           tags: [ProductTag(siteID: sampleSiteID, tagID: 100, name: "My new tag", slug: "my-new-tag")])
        productStore.upsertStoredProduct(readOnlyProduct: productMutated, in: viewStorage)
        let productMutatedStored = viewStorage.loadProduct(siteID: self.sampleSiteID, productID: self.sampleProductID)

        XCTAssertEqual(productMutated.tags.map { $0.tagID }, productMutatedStored?.tagsArray.map { $0.tagID })
    }

    // MARK: - ProductAction.retrieveProducts

    /// Verifies that ProductAction.retrieveProducts effectively persists any retrieved products.
    ///
    func testRetrievingProductsEffectivelyPersistsRetrievedProducts() {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProduct = MockProduct().product(siteID: sampleSiteID, productID: sampleProductID, buttonText: "Deal", externalURL: "https://example.com")
        remote.whenLoadingProducts(siteID: sampleSiteID, productIDs: [sampleProductID], thenReturn: .success([expectedProduct]))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let expectation = self.expectation(description: "Retrieve product list")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // Action
        var retrievedProducts: [Networking.Product]?
        let action = ProductAction.retrieveProducts(siteID: sampleSiteID, productIDs: [sampleProductID]) { result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success((let products, let hasNextPage)):
                retrievedProducts = products
                XCTAssertFalse(hasNextPage)
            }
            expectation.fulfill()
        }
        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Assert
        XCTAssertEqual(retrievedProducts, [expectedProduct])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
    }

    func test_retrieving_products_of_the_same_page_size_has_next_page() {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProducts: [Yosemite.Product] = .init(repeating: MockProduct().product(), count: 25)
        remote.whenLoadingProducts(siteID: sampleSiteID, productIDs: [sampleProductID], thenReturn: .success(expectedProducts))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        var result: Result<(products: [Yosemite.Product], hasNextPage: Bool), Error>?
        waitForExpectation { expectation in
            let action = ProductAction.retrieveProducts(siteID: sampleSiteID, productIDs: [sampleProductID], pageNumber: 1, pageSize: 25) { aResult in
                result = aResult
                expectation.fulfill()
            }
            productStore.onAction(action)
        }

        // Assert
        guard case let .success((products: products, hasNextPage: hasNextPage)) = result else {
            XCTFail("Unexpected result: \(String(describing: result))")
            return
        }
        XCTAssertEqual(products, expectedProducts)
        XCTAssertTrue(hasNextPage)
    }

    func test_retrieving_products_of_smaller_size_than_page_size_has_no_next_page() {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProducts: [Yosemite.Product] = .init(repeating: MockProduct().product(), count: 24)
        remote.whenLoadingProducts(siteID: sampleSiteID, productIDs: [sampleProductID], thenReturn: .success(expectedProducts))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        var result: Result<(products: [Yosemite.Product], hasNextPage: Bool), Error>?
        waitForExpectation { expectation in
            let action = ProductAction.retrieveProducts(siteID: sampleSiteID, productIDs: [sampleProductID], pageNumber: 1, pageSize: 25) { aResult in
                result = aResult
                expectation.fulfill()
            }
            productStore.onAction(action)
        }

        // Assert
        guard case let .success((products: products, hasNextPage: hasNextPage)) = result else {
            XCTFail("Unexpected result: \(String(describing: result))")
            return
        }
        XCTAssertEqual(products, expectedProducts)
        XCTAssertFalse(hasNextPage)
    }

    /// Verifies that ProductAction.retrieveProducts with a page number and size makes a network request that includes these params.
    ///
    func testRetrievingProductsMakesANetworkRequestWithTheExpectedPageNumberAndSize() {
        // Arrange
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Action
        let pageNumber = 6
        let pageSize = 36
        let action = ProductAction.retrieveProducts(siteID: sampleSiteID, productIDs: [sampleProductID], pageNumber: pageNumber, pageSize: pageSize) { _ in }
        productStore.onAction(action)

        // Assert
        guard let pathComponents = network.pathComponents else {
            XCTFail("Cannot parse path from the API request")
            return
        }

        let expectedPageNumberParam = "page=\(pageNumber)"
        XCTAssertTrue(pathComponents.contains(expectedPageNumberParam), "Expected to have param: \(expectedPageNumberParam)")

        let expectedPageSizeParam = "per_page=\(pageSize)"
        XCTAssertTrue(pathComponents.contains(expectedPageSizeParam), "Expected to have param: \(expectedPageSizeParam)")
    }

    /// Verifies that ProductAction.retrieveProducts always returns an empty result for an empty array of product IDs.
    ///
    func testRetrievingProductsWithEmptyIDsReturnsAnEmptyResult() {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProduct = MockProduct().product(siteID: sampleSiteID, productID: sampleProductID, buttonText: "Deal", externalURL: "https://example.com")
        // The mock remote returns a non-empty result for an empty array of product IDs.
        remote.whenLoadingProducts(siteID: sampleSiteID, productIDs: [], thenReturn: .success([expectedProduct]))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let expectation = self.expectation(description: "Retrieve product list")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // Action
        var retrievedProducts: [Networking.Product]?
        let action = ProductAction.retrieveProducts(siteID: sampleSiteID, productIDs: []) { result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success((let products, let hasNextPage)):
                retrievedProducts = products
                XCTAssertFalse(hasNextPage)
            }
            expectation.fulfill()
        }
        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Assert
        XCTAssertEqual(retrievedProducts, [])
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
    }

    func test_calling_replaceProductLocally_replaces_product_locally() throws {
        // Given
        let product = sampleProduct()
        storageManager.insertSampleProduct(readOnlyProduct: product)

        let remote = MockProductsRemote()
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let newProduct = product.copy(variations: [1, 2, 3])
        let finished: Bool = waitFor { promise in
            let action = ProductAction.replaceProductLocally(product: newProduct, onCompletion: {
                promise(true)
            })
            productStore.onAction(action)
        }

        // Then
        let replacedProduct = storageManager.viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)?.toReadOnly()
        XCTAssertEqual(newProduct, replacedProduct)
        XCTAssertTrue(finished)
    }
}

// MARK: - Private Helpers
//
private extension ProductStoreTests {

    func sampleProduct(_ siteID: Int64? = nil,
                       productID: Int64? = nil,
                       productShippingClass: Networking.ProductShippingClass? = nil,
                       tags: [Networking.ProductTag]? = nil,
                       downloadable: Bool = false) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID
        let testProductID = productID ?? sampleProductID
        return Product(siteID: testSiteID,
                       productID: testProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       date: date(with: "2019-02-19T17:33:31"),
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       dateOnSaleStart: date(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: date(with: "2019-10-27T21:29:59"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       shortDescription: """
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
                       downloadable: downloadable,
                       downloads: downloadable ? sampleDownloads() : [],
                       downloadLimit: downloadable ? 1 : -1,
                       downloadExpiry: downloadable ? 1 : -1,
                       buttonText: "",
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
                       shippingClass: productShippingClass?.slug ?? "",
                       shippingClassID: productShippingClass?.shippingClassID ?? 0,
                       productShippingClass: productShippingClass,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: sampleCategories(),
                       tags: tags ?? sampleTags(siteID: testSiteID),
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

    func sampleCategories(parentID: Int64 = 0) -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, siteID: sampleSiteID, parentID: parentID, name: "Events", slug: "events")
        return [category1]
    }

    func sampleTags(siteID: Int64) -> [Networking.ProductTag] {
        let tag1 = ProductTag(siteID: siteID, tagID: 37, name: "room", slug: "room")
        let tag2 = ProductTag(siteID: siteID, tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(siteID: siteID, tagID: 39, name: "30", slug: "30")
        let tag4 = ProductTag(siteID: siteID, tagID: 40, name: "20+", slug: "20")
        let tag5 = ProductTag(siteID: siteID, tagID: 41, name: "meeting room", slug: "meeting-room")
        let tag6 = ProductTag(siteID: siteID, tagID: 42, name: "meetings", slug: "meetings")
        let tag7 = ProductTag(siteID: siteID, tagID: 43, name: "parties", slug: "parties")
        let tag8 = ProductTag(siteID: siteID, tagID: 44, name: "graduation", slug: "graduation")
        let tag9 = ProductTag(siteID: siteID, tagID: 45, name: "birthday party", slug: "birthday-party")

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
        let attribute1 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
                                          name: "Color",
                                          position: 1,
                                          visible: true,
                                          variation: true,
                                          options: ["Purple", "Yellow", "Hot Pink", "Lime Green", "Teal"])

        let attribute2 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
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
                                        fileURL: "https://example.com/woo-single-1.ogg")
        let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                        name: "Artwork",
                                        fileURL: "https://example.com/cd_4_angle.jpg")
        let download3 = ProductDownload(downloadID: "240cd543-5457-498e-95e2-6b51fdaf15cc",
                                        name: "Artwork 2",
                                        fileURL: "https://example.com/cd_4_flat.jpg")
        return [download1, download2, download3]
    }

    func sampleDownloadsMutated() -> [Networking.ProductDownload] {
        let download1 = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                        name: "Song #1",
                                        fileURL: "https://example.com/woo-single-1.ogg")
        let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                        name: "Artwork",
                                        fileURL: "https://example.com/cd_4_angle.jpg")
        return [download1, download2]
    }

    func sampleProductMutated(_ siteID: Int64? = nil) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID

        return Product(siteID: testSiteID,
                       productID: sampleProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       date: date(with: "2019-02-19T17:33:31"),
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       dateOnSaleStart: date(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: date(with: "2019-10-27T21:29:59"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       shortDescription: """
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
                       downloads: sampleDownloadsMutated(),
                       downloadLimit: 1,
                       downloadExpiry: 1,
                       buttonText: "",
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
                       productShippingClass: nil,
                       reviewsAllowed: false,
                       averageRating: "1.30",
                       ratingCount: 76,
                       relatedIDs: [31, 22, 369],
                       upsellIDs: [99, 123, 234, 444],
                       crossSellIDs: [1234, 234234, 999, 989],
                       parentID: 444,
                       purchaseNote: "Whatever!",
                       categories: sampleCategoriesMutated(),
                       tags: sampleTagsMutated(siteID: testSiteID),
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
        let category1 = ProductCategory(categoryID: 36, siteID: sampleSiteID, parentID: 0, name: "Events", slug: "events")
        let category2 = ProductCategory(categoryID: 362, siteID: sampleSiteID, parentID: 0, name: "Other Stuff", slug: "other")
        return [category1, category2]
    }

    func sampleTagsMutated(siteID: Int64) -> [Networking.ProductTag] {
        let tag1 = ProductTag(siteID: siteID, tagID: 37, name: "something", slug: "something")
        let tag2 = ProductTag(siteID: siteID, tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(siteID: siteID, tagID: 39, name: "3000", slug: "3000")
        let tag4 = ProductTag(siteID: siteID, tagID: 45, name: "birthday party", slug: "birthday-party")
        let tag5 = ProductTag(siteID: siteID, tagID: 95, name: "yep", slug: "yep")

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
        let attribute1 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
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

    func sampleProductShippingClass(remoteID: Int64, siteID: Int64) -> Yosemite.ProductShippingClass {
        return ProductShippingClass(count: 3,
                                    descriptionHTML: "Limited offer!",
                                    name: "Free Shipping",
                                    shippingClassID: remoteID,
                                    siteID: siteID,
                                    slug: "")
    }

    func sampleVariationTypeProduct(_ siteID: Int64? = nil) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID
        return Product(siteID: testSiteID,
                       productID: sampleVariationTypeProductID,
                       name: "Paper Airplane - Black, Long",
                       slug: "paper-airplane-3",
                       permalink: "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Long",
                       date: date(with: "2019-04-04T22:06:45"),
                       dateCreated: date(with: "2019-04-04T22:06:45"),
                       dateModified: date(with: "2019-04-09T20:24:03"),
                       dateOnSaleStart: nil,
                       dateOnSaleEnd: nil,
                       productTypeKey: "variation",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>Long paper airplane. Color is black. </p>\n",
                       shortDescription: "",
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
                       buttonText: "",
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
                       productShippingClass: nil,
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
        let attribute1 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
                                          name: "Color",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Black"])

        let attribute2 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
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
