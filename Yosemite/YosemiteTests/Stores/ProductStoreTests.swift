import XCTest
import TestKit
import Fakes
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
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID,
                                                  productID: sampleProductID,
                                                  downloads: sampleDownloads(),
                                                  dimensions: ProductDimensions(length: "12", width: "26", height: "16"),
                                                  shippingClass: "2-day",
                                                  shippingClassID: 1,
                                                  categories: [mockCategory],
                                                  tags: [mockTag],
                                                  images: [mockImage],
                                                  attributes: [mockAttribute],
                                                  defaultAttributes: [mockDefaultAttribute],
                                                  addOns: sampleAddOns(),
                                                  bundledItems: [.fake()],
                                                  password: "Caput Draconis",
                                                  compositeComponents: [.fake()],
                                                  subscription: .fake())
        remote.whenAddingProduct(siteID: sampleSiteID, thenReturn: .success(expectedProduct))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 0, password: "Caput Draconis")

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
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAddOn.self), 3)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAddOnOption.self), 7)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCompositeComponent.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductSubscription.self), 1)
    }

    func test_addProduct_returns_error_upon_network_error() {
        // Arrange
        let remote = MockProductsRemote()
        remote.whenAddingProduct(siteID: sampleSiteID, thenReturn: .failure(DotcomError.requestFailed))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 0)

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
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID,
                                                  productID: sampleProductID,
                                                  dimensions: ProductDimensions(length: "12", width: "26", height: "16"),
                                                  shippingClass: "2-day",
                                                  shippingClassID: 1,
                                                  categories: [mockCategory],
                                                  tags: [mockTag],
                                                  images: [mockImage],
                                                  attributes: [mockAttribute],
                                                  defaultAttributes: [mockDefaultAttribute],
                                                  addOns: sampleAddOns(),
                                                  bundledItems: [.fake()],
                                                  password: "Caput Draconis",
                                                  compositeComponents: [.fake()],
                                                  subscription: .fake())
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
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAddOn.self), 3)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAddOnOption.self), 7)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCompositeComponent.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductSubscription.self), 1)

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
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAddOn.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductAddOnOption.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCompositeComponent.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductSubscription.self), 0)
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
                                                       productCategory: nil,
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
        let remoteProduct = sampleProduct(addOns: [])

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let action = ProductAction.synchronizeProducts(siteID: sampleSiteID,
                                                       pageNumber: defaultPageNumber,
                                                       pageSize: defaultPageSize,
                                                       stockStatus: nil,
                                                       productStatus: nil,
                                                       productType: nil,
                                                       productCategory: nil,
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
                                                       productCategory: nil,
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
                                                       productCategory: nil,
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
                                                       productCategory: nil,
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
                                                       productCategory: nil,
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
                                                           productCategory: nil,
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
                                                           productCategory: nil,
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
                                                       productCategory: nil,
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
                                                       productCategory: nil,
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
    func test_retrieve_single_product_returns_expected_fields() throws {
        // Arrange
        // The shipping class ID should match the `shipping_class_id` field in `product.json`.
        let expectedShippingClass = sampleProductShippingClass(remoteID: 134, siteID: sampleSiteID)
        storageManager.insertSampleProductShippingClass(readOnlyProductShippingClass: expectedShippingClass)

        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteProduct = sampleProduct(productShippingClass: expectedShippingClass, downloadable: true, isSampleItem: true).copy(password: "Fortuna Major")

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
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, buttonText: "Deal", externalURL: "https://example.com")
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

        let remoteProduct = sampleProduct(productShippingClass: expectedShippingClass, downloadable: true, isSampleItem: true).copy(password: "Fortuna Major")

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
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCompositeComponent.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductSubscription.self), 0)

        productStore.upsertStoredProduct(readOnlyProduct: sampleProduct(downloadable: true), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductTag.self, matching: NSPredicate(format: "siteID == %lld", sampleSiteID)), 9)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductCategory.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductImage.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDimensions.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDefaultAttribute.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductDownload.self), 3)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCompositeComponent.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductSubscription.self), 0)

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
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 2)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductCompositeComponent.self), 2)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductSubscription.self), 1)
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
        let derivedContext = storageManager.writerDerivedStorage

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

    /// Verifies that `ProductStore.upsertStoredProduct` does not store products with the `importing` product status.
    ///
    func test_upsertStoredProduct_does_not_store_import_placeholder_products() {
        // Given
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let product = Product.fake().copy(statusKey: "importing")
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        productStore.upsertStoredProduct(readOnlyProduct: product, in: viewStorage)

        // Then
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Product.self), 0)
    }

    // MARK: - ProductAction.searchProducts

    /// Verifies that `ProductAction.searchProducts` effectively persists the retrieved products.
    ///
    func test_searchProducts_effectively_persists_retrieved_search_products() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // A product that is expected to be in the search results.
        let expectedProductID: Int64 = 67
        let expectedProductName = "Photo"

        // When
        let keyword = "photo"
        let result: Result<Bool, Error> = waitFor { promise in
            let action = ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                      keyword: keyword,
                                                      pageNumber: self.defaultPageNumber,
                                                      pageSize: self.defaultPageSize,
                                                      onCompletion: { result in
                                                        promise(result)
                                                      })
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let expectedProduct = try XCTUnwrap(viewStorage.loadProduct(siteID: sampleSiteID, productID: expectedProductID)?.toReadOnly())
        XCTAssertEqual(expectedProduct.name, expectedProductName)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 2)
    }

    /// Verifies that `ProductAction.searchProducts` effectively upserts the `ProductSearchResults` entity.
    ///
    func test_searchProducts_effectively_persists_search_results_entity() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        let keyword = "hiii"
        let result: Result<Bool, Error> = waitFor { promise in
            let action = ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                      keyword: keyword,
                                                      pageNumber: self.defaultPageNumber,
                                                      pageSize: self.defaultPageSize,
                                                      onCompletion: { result in
                                                        promise(result)
                                                      })
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let searchResults = try XCTUnwrap(viewStorage.loadProductSearchResults(keyword: keyword, filterKey: ProductSearchFilter.all.rawValue))
        XCTAssertEqual(searchResults.keyword, keyword)
        XCTAssertEqual(searchResults.products?.count, viewStorage.countObjects(ofType: Storage.Product.self))

        let anotherKeyword = "hello"
        let searchResultsWithAnotherKeyword = viewStorage.loadProductSearchResults(keyword: anotherKeyword, filterKey: ProductSearchFilter.all.rawValue)
        XCTAssertNil(searchResultsWithAnotherKeyword)
    }

    /// Verifies that `ProductAction.searchProducts` effectively persists the retrieved products.
    ///
    func test_searchProducts_effectively_persists_product_bundle_items() throws {
        // Given
        let remote = MockProductsRemote()
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let mockBundleItem = ProductBundleItem(bundledItemID: 6,
                                               productID: 16,
                                               menuOrder: 1,
                                               title: "Scarf",
                                               stockStatus: .inStock,
                                               minQuantity: 2,
                                               maxQuantity: nil,
                                               defaultQuantity: 6,
                                               isOptional: true,
                                               overridesVariations: true,
                                               allowedVariations: [12, 18],
                                               overridesDefaultVariationAttributes: true,
                                               defaultVariationAttributes: [.init(id: 2, name: "Material", option: "Silk")],
                                               pricedIndividually: true)
        let mockProduct = Product.fake().copy(bundledItems: [mockBundleItem])
        remote.whenSearchingProducts(query: "Accessory", thenReturn: .success([mockProduct]))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                               keyword: "Accessory",
                                                               pageNumber: self.defaultPageNumber,
                                                               pageSize: self.defaultPageSize,
                                                               excludedProductIDs: [],
                                                               onCompletion: { _ in
                promise(())
            }))
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductBundleItem.self), 1)
        let storageBundleItem = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.ProductBundleItem.self))
        assertEqual(mockBundleItem, storageBundleItem.toReadOnly())
    }

    func test_searchProducts_effectively_persists_product_bundle_properties() throws {
        // Given
        let remote = MockProductsRemote()
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let mockProduct = Product.fake().copy(bundleMinSize: 2, bundleMaxSize: 6)
        remote.whenSearchingProducts(query: "Accessory", thenReturn: .success([mockProduct]))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                               keyword: "Accessory",
                                                               pageNumber: self.defaultPageNumber,
                                                               pageSize: self.defaultPageSize,
                                                               excludedProductIDs: [],
                                                               onCompletion: { _ in
                promise(())
            }))
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
        let product = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Product.self)?.toReadOnly())
        XCTAssertEqual(product.bundleMinSize, 2)
        XCTAssertEqual(product.bundleMaxSize, 6)
    }

    func test_searchProductsInCache_then_effectively_persists_search_results_entity() throws {
        // Given
        let keyword = "test"
        let product = sampleProduct(name: keyword)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let thereAreCachedResults: Bool = waitFor { promise in
            let action = ProductAction.searchProductsInCache(siteID: self.sampleSiteID,
                                                             keyword: keyword,
                                                             pageSize: self.defaultPageSize,
                                                             onCompletion: { result in
                promise(result)
            })

            store.onAction(action)
        }

        // Then
        XCTAssertTrue(thereAreCachedResults)
        let searchResults = try XCTUnwrap(viewStorage.loadProductSearchResults(keyword: keyword, filterKey: ProductSearchFilter.all.rawValue))
        XCTAssertEqual(searchResults.keyword, keyword)
        XCTAssertEqual(searchResults.products?.count, viewStorage.countObjects(ofType: Storage.Product.self))

        let anotherKeyword = "hello"
        let searchResultsWithAnotherKeyword = viewStorage.loadProductSearchResults(keyword: anotherKeyword, filterKey: ProductSearchFilter.all.rawValue)
        XCTAssertNil(searchResultsWithAnotherKeyword)
    }

    /// Verifies that `ProductAction.searchProducts` does not result in duplicated entries in the ProductSearchResults entity.
    ///
    func test_searchProducts_does_not_produce_duplicated_references() {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        let keyword = "hiii"
        let result: Result<Bool, Error> = waitFor { promise in
            let nestedAction = ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                            keyword: keyword,
                                                            pageNumber: self.defaultPageNumber,
                                                            pageSize: self.defaultPageSize,
                                                            onCompletion: { result in
                                                                promise(result)
                                                            })
            let firstAction = ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                           keyword: keyword,
                                                           pageNumber: self.defaultPageNumber,
                                                           pageSize: self.defaultPageSize,
                                                           onCompletion: { result in
                                                            store.onAction(nestedAction)
                                                           })
            store.onAction(firstAction)
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let products = viewStorage.allObjects(ofType: Storage.Product.self, matching: nil, sortedBy: nil)
        XCTAssertEqual(products.count, 10)
        for product in products {
            XCTAssertEqual(product.searchResults?.count, 1)
            XCTAssertEqual(product.searchResults?.first?.keyword, keyword)
        }

        let searchResults = viewStorage.allObjects(ofType: Storage.ProductSearchResults.self, matching: nil, sortedBy: nil)
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults.first?.products?.count, 10)
        XCTAssertEqual(searchResults.first?.keyword, keyword)
    }

    func test_searchProducts_triggers_remote_request_with_filters() {
        // Given
        let remote = MockProductsRemote()
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        let filteredStockStatus: ProductStockStatus = .outOfStock
        let filteredProductStatus: ProductStatus = .draft
        let filteredProductType: ProductType = .simple
        let filteredProductCategory: Networking.ProductCategory = .init(categoryID: 123, siteID: sampleSiteID, parentID: 1, name: "Test", slug: "test")

        // When
        let searchAction = ProductAction.searchProducts(siteID: sampleSiteID,
                                                        keyword: "hiii",
                                                        pageNumber: defaultPageNumber,
                                                        pageSize: defaultPageSize,
                                                        stockStatus: filteredStockStatus,
                                                        productStatus: filteredProductStatus,
                                                        productType: filteredProductType,
                                                        productCategory: filteredProductCategory,
                                                        excludedProductIDs: [],
                                                        onCompletion: { _ in })
        productStore.onAction(searchAction)

        // Then
        XCTAssertTrue(remote.searchProductTriggered)
        assertEqual(filteredStockStatus, remote.searchProductWithStockStatus)
        assertEqual(filteredProductType, remote.searchProductWithProductType)
        assertEqual(filteredProductStatus, remote.searchProductWithProductStatus)
        assertEqual(filteredProductCategory, remote.searchProductWithProductCategory)
    }

    func test_searchProducts_sets_hasNextPage_to_true_if_product_count_is_the_same_as_pageSize() throws {
        // Given
        let remote = MockProductsRemote()
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let keyword = "woo"
        let pageSize = 5
        remote.whenSearchingProducts(query: keyword, thenReturn: .success(Array(repeating: Product.fake(), count: pageSize)))

        // When
        let result = waitFor { promise in
            store.onAction(ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                            keyword: keyword,
                                                            pageNumber: self.defaultPageNumber,
                                                            pageSize: pageSize,
                                                            onCompletion: { result in
                                                                promise(result)
                                                            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let hasNextPage = try XCTUnwrap(result.get())
        XCTAssertTrue(hasNextPage)
    }

    func test_searchProducts_sets_hasNextPage_to_false_if_product_count_is_smaller_than_pageSize() throws {
        // Given
        let remote = MockProductsRemote()
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        let keyword = "woo"
        let pageSize = 5
        remote.whenSearchingProducts(query: keyword, thenReturn: .success(Array(repeating: Product.fake(), count: pageSize - 1)))

        // When

        let result = waitFor { promise in
            store.onAction(ProductAction.searchProducts(siteID: self.sampleSiteID,
                                                            keyword: keyword,
                                                            pageNumber: self.defaultPageNumber,
                                                            pageSize: pageSize,
                                                            onCompletion: { result in
                                                                promise(result)
                                                            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let hasNextPage = try XCTUnwrap(result.get())
        XCTAssertFalse(hasNextPage)
    }

    // MARK: - ProductAction.updateProduct

    /// Verifies that `ProductAction.updateProduct` returns the expected `Product`.
    ///
    func test_updating_product_returns_expected_fields() {
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
        let expectedProductSaleStart = DateFormatter.dateFromString(with: "2019-10-15T21:30:11")
        let expectedProductSaleEnd = DateFormatter.dateFromString(with: "2019-10-27T21:29:50")
        let expectedProductTaxStatus = "taxable"
        let expectedProductTaxClass = "reduced-rate"
        let expectedDownloadableFileCount = 0
        let expectedDownloadable = false
        let expectedBundleStockStatus = ProductStockStatus.insufficientStock
        let expectedBundleStockQuantity: Int64 = 0
        let expectedPassword: String = "Caput Draconis"

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
            XCTAssertEqual(product.bundleStockStatus, expectedBundleStockStatus)
            XCTAssertEqual(product.bundleStockQuantity, expectedBundleStockQuantity)
            XCTAssertNil(product.bundleMinSize)
            XCTAssertNil(product.bundleMaxSize)
            XCTAssertEqual(product.password, expectedPassword)

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

        network.simulateError(requestUrlSuffix: "products/\(sampleProductID)", error: NetworkError.notFound())

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

    // MARK: - ProductAction.updateProductImages

    /// Verifies that `ProductAction.updateProductImages` effectively persists the returned product.
    ///
    func test_updateProductImages_with_success_persists_returned_product() throws {
        // Given
        let remote = MockProductsRemote()
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID)
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        remote.whenUpdatingProductImages(siteID: sampleSiteID, productID: sampleProductID, thenReturn: .success(expectedProduct))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        let result: Result<Yosemite.Product, ProductUpdateError> = waitFor { promise in
            let action = ProductAction.updateProductImages(siteID: self.sampleSiteID,
                                                           productID: self.sampleProductID,
                                                           images: []) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let returnedProduct = try XCTUnwrap(result.get())
        assertEqual(expectedProduct, returnedProduct)
        let productFromStorage = try XCTUnwrap(viewStorage.loadProduct(siteID: sampleSiteID, productID: sampleProductID)?.toReadOnly())
        assertEqual(expectedProduct, productFromStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)
    }

    func test_updateProductImages_with_failure_returns_error() {
        // Given
        let remote = MockProductsRemote()
        let networkError = ProductUpdateError.passwordCannotBeUpdated
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        remote.whenUpdatingProductImages(siteID: sampleSiteID, productID: sampleProductID, thenReturn: .failure(networkError))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)

        // When
        let result: Result<Yosemite.Product, ProductUpdateError> = waitFor { promise in
            let action = ProductAction.updateProductImages(siteID: self.sampleSiteID,
                                                           productID: self.sampleProductID,
                                                           images: []) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure, .init(error: networkError))
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 0)
    }

    // MARK: ProductAction.updateProducts

    /// Verifies that `ProductAction.updateProducts` returns the expected `Products`.
    ///
    func test_updateProducts_is_correctly_updating_products() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products/batch", filename: "products-batch-update")
        let product = sampleProduct(addOns: [])
        storageManager.insertSampleProduct(readOnlyProduct: product)

        // When
        let result = waitFor { promise in
            let action = ProductAction.updateProducts(siteID: self.sampleSiteID, products: [product]) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let updatedProducts = try result.get()
        assertEqual(updatedProducts, [product])
    }

    // MARK: - ProductAction.retrieveProducts

    /// Verifies that ProductAction.retrieveProducts effectively persists any retrieved products.
    ///
    func testRetrievingProductsEffectivelyPersistsRetrievedProducts() {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, buttonText: "Deal", externalURL: "https://example.com")
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
        let expectedProducts: [Yosemite.Product] = .init(repeating: Product.fake(), count: 25)
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
        let expectedProducts: [Yosemite.Product] = .init(repeating: Product.fake(), count: 24)
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
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let expectedPageNumberParam = "page=\(pageNumber)"
        XCTAssertTrue(queryParameters.contains(expectedPageNumberParam), "Expected to have param: \(expectedPageNumberParam)")

        let expectedPageSizeParam = "per_page=\(pageSize)"
        XCTAssertTrue(queryParameters.contains(expectedPageSizeParam), "Expected to have param: \(expectedPageSizeParam)")
    }

    /// Verifies that ProductAction.retrieveProducts always returns an empty result for an empty array of product IDs.
    ///
    func testRetrievingProductsWithEmptyIDsReturnsAnEmptyResult() {
        // Arrange
        let remote = MockProductsRemote()
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, buttonText: "Deal", externalURL: "https://example.com")
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

    /// Verifies that `ProductAction.retrieveProducts` effectively persists the fields added by the Min/Max Quantities extension.
    ///
    func test_retrieve_products_effectively_persists_mix_max_quantity_fields() throws {
        let remote = MockProductsRemote()
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID,
                                                  productID: sampleProductID,
                                                  minAllowedQuantity: "4",
                                                  maxAllowedQuantity: "200",
                                                  groupOfQuantity: "2",
                                                  combineVariationQuantities: false)
        remote.whenLoadingProducts(siteID: sampleSiteID, productIDs: [sampleProductID], thenReturn: .success([expectedProduct]))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Action
        let storedProduct: Yosemite.Product? = waitFor { promise in
            let action = ProductAction.retrieveProducts(siteID: self.sampleSiteID, productIDs: [self.sampleProductID]) { _ in
                let storedProduct = self.viewStorage.loadProduct(siteID: self.sampleSiteID, productID: self.sampleProductID)
                let readOnlyStoredProduct = storedProduct?.toReadOnly()
                promise(readOnlyStoredProduct)
            }
            productStore.onAction(action)
        }

        XCTAssertNotNil(storedProduct)
        XCTAssertEqual(storedProduct, expectedProduct)
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

    // MARK: - ProductAction.checkIfStoreHasProducts

    /// Verifies that ProductAction.checkIfStoreHasProducts returns true result when remote returns an array with a product ID.
    ///
    func test_checkIfStoreHasProducts_returns_expected_result_when_remote_returns_product() throws {
        // Given
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-ids-only")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = ProductAction.checkIfStoreHasProducts(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasProducts = try XCTUnwrap(result.get())
        XCTAssertTrue(hasProducts)
    }

    /// Verifies that ProductAction.checkIfStoreHasProducts returns false result when a product already exists in local storage.
    ///
    func test_checkIfStoreHasProducts_with_IDs_returns_expected_result_when_local_storage_has_product() throws {
        // Given
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: sampleSiteID))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = ProductAction.checkIfStoreHasProducts(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasProducts = try XCTUnwrap(result.get())
        XCTAssertTrue(hasProducts)
    }

    /// Verifies that ProductAction.checkIfStoreHasProducts returns true result for an empty array.
    ///
    func test_checkIfStoreHasProducts_returns_expected_result_when_remote_returns_empty_array() throws {
        // Given
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-ids-only-empty")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = ProductAction.checkIfStoreHasProducts(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasProducts = try XCTUnwrap(result.get())
        XCTAssertFalse(hasProducts)
    }

    func test_checkIfStoreHasProducts_returns_expected_result_when_local_storage_has_no_product_of_given_stautus_and_remote_returns_empty_array() throws {
        // Given
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: sampleSiteID, statusKey: "draft"))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-ids-only-empty")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = ProductAction.checkIfStoreHasProducts(siteID: self.sampleSiteID, status: .published) { result in
                promise(result)
            }
            productStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasPublishedProducts = try XCTUnwrap(result.get())
        XCTAssertFalse(hasPublishedProducts)
    }

    // MARK: - ProductAction.generateProductDescription

    func test_generateProductDescription_returns_text_on_success() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success("Trendy product"))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductDescription(siteID: self.sampleSiteID,
                                                                           name: "A product",
                                                                           features: "Trendy",
                                                                           language: "en") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let generatedText = try XCTUnwrap(result.get())
        XCTAssertEqual(generatedText, "Trendy product")
    }

    func test_generateProductDescription_returns_error_on_failure() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductDescription(siteID: self.sampleSiteID,
                                                                           name: "A product",
                                                                           features: "Trendy",
                                                                           language: "en") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_generateProductDescription_includes_parameters_in_remote_base_parameter() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductDescription(siteID: self.sampleSiteID,
                                                                           name: "A product name",
                                                                           features: "Trendy, cool, fun",
                                                                           language: "en") { _ in
                promise(())
            })
        }

        // Then
        let base = try XCTUnwrap(generativeContentRemote.generateTextBase)
        XCTAssertTrue(base.contains("```A product name```"))
        XCTAssertTrue(base.contains("```Trendy, cool, fun```"))
        XCTAssertTrue(base.contains("en"))
    }

    func test_generateProductDescription_uses_correct_feature() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductDescription(siteID: self.sampleSiteID,
                                                                           name: "A product name",
                                                                           features: "Trendy, cool, fun",
                                                                           language: "en") { _ in
                promise(())
            })
        }

        // Then
        let feature = try XCTUnwrap(generativeContentRemote.generateTextFeature)
        XCTAssertEqual(feature, GenerativeContentRemoteFeature.productDescription)
    }

    func test_generateProductDescription_uses_correct_response_format() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductDescription(siteID: self.sampleSiteID,
                                                                           name: "A product name",
                                                                           features: "Trendy, cool, fun",
                                                                           language: "en") { _ in
                promise(())
            })
        }

        // Then
        let format = try XCTUnwrap(generativeContentRemote.generateTextResponseFormat)
        XCTAssertEqual(format, .text)
    }

    // MARK: - ProductAction.generateProductSharingMessage

    func test_generateProductSharingMessage_returns_text_on_success() throws {
        // Given
        let expectedText = "Check out this cool product"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(expectedText))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductSharingMessage(
                siteID: self.sampleSiteID,
                url: "https://example.com",
                name: "Sample product",
                description: "Sample description",
                language: "en"
            ) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let generatedText = try XCTUnwrap(result.get())
        XCTAssertEqual(generatedText, expectedText)
    }

    func test_generateProductSharingMessage_returns_text_after_trimming_quotation_marks() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success("\"This is \"AI\" generated message.\""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductSharingMessage(
                siteID: self.sampleSiteID,
                url: "https://example.com",
                name: "Sample product",
                description: "Sample description",
                language: "en"
            ) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let generatedText = try XCTUnwrap(result.get())
        XCTAssertEqual(generatedText, "This is \"AI\" generated message.")
    }

    func test_generateProductSharingMessage_returns_error_on_failure() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductSharingMessage(
                siteID: self.sampleSiteID,
                url: "https://example.com",
                name: "Sample product",
                description: "Sample description",
                language: "en"
            ) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_generateProductSharingMessage_includes_parameters_in_remote_base_parameter() throws {
        // Given
        let expectedURL = "https://example.com"
        let expectedName = "Sample product"
        let expectedDescription = "Sample description"
        let expectedLangugae = "en"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenIdentifyingLanguage(thenReturn: .success(""))
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductSharingMessage(
                siteID: self.sampleSiteID,
                url: expectedURL,
                name: expectedName,
                description: expectedDescription,
                language: expectedLangugae
            ) { result in
                promise(())
            })
        }

        // Then
        let base = try XCTUnwrap(generativeContentRemote.generateTextBase)
        XCTAssertTrue(base.contains(expectedURL))
        XCTAssertTrue(base.contains(expectedName))
        XCTAssertTrue(base.contains(expectedDescription))
        XCTAssertTrue(base.contains(expectedLangugae))
    }

    func test_generateProductSharingMessage_uses_correct_feature() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductSharingMessage(
                siteID: self.sampleSiteID,
                url: "https://example.com",
                name: "Sample product",
                description: "Sample description",
                language: "en"
            ) { result in
                promise(())
            })
        }

        // Then
        let feature = try XCTUnwrap(generativeContentRemote.generateTextFeature)
        XCTAssertEqual(feature, GenerativeContentRemoteFeature.productSharing)
    }

    func test_generateProductSharingMessage_uses_correct_response_format() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductSharingMessage(
                siteID: self.sampleSiteID,
                url: "https://example.com",
                name: "Sample product",
                description: "Sample description",
                language: "en"
            ) { result in
                promise(())
            })
        }

        // Then
        let format = try XCTUnwrap(generativeContentRemote.generateTextResponseFormat)
        XCTAssertEqual(format, .text)
    }

    // MARK: - ProductAction.identifyLanguage

    func test_identifyLanguage_returns_language_on_success() throws {
        // Given
        let expectedLanguage = "en"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenIdentifyingLanguage(thenReturn: .success(expectedLanguage))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.identifyLanguage(siteID: self.sampleSiteID,
                                                                 string: "Woo is awesome",
                                                                 feature: .productSharing) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let generatedText = try XCTUnwrap(result.get())
        XCTAssertEqual(generatedText, expectedLanguage)
    }

    func test_identifyLanguage_returns_error_on_identify_language_failure() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenIdentifyingLanguage(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.identifyLanguage(siteID: self.sampleSiteID,
                                                                 string: "Woo is awesome",
                                                                 feature: .productSharing) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }


    // MARK: - ProductAction.retrieveFirstPurchasableItemMatchFromSKU

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_successful_exact_SKU_match_product_then_returns_matched_product() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

        // The product that is expected to be in the search results
        let expectedProductID: Int64 = 2783
        let expectedProductName = "Chocolate bars"
        let expectedProductSKU = "chocobars"

        // When
        let productSKU = "chocobars"
        let result = waitFor { promise in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                        sku: productSKU,
                                                                        onCompletion: { product in
                promise(product)
            })
            store.onAction(action)
        }

        let skuSearchResult = try XCTUnwrap(result.get())

        guard case let .product(productMatch) = skuSearchResult else {
            return XCTFail("It didn't provide a product as expected")
        }

        XCTAssertEqual(productMatch.productID, expectedProductID)
        XCTAssertEqual(productMatch.name, expectedProductName)
        XCTAssertEqual(productMatch.sku, expectedProductSKU)
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_successful_exact_SKU_match_product_variation_then_returns_matched_product_variation() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search-variation")

        // The product that is expected to be in the search results
        let expectedProductID: Int64 = 2783
        let expectedParentID: Int64 = 846
        let expectedProductSKU = "chocobars"

        // When
        let productSKU = "chocobars"
        let result = waitFor { promise in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                        sku: productSKU,
                                                                        onCompletion: { product in
                promise(product)
            })
            store.onAction(action)
        }

        let skuSearchResult = try XCTUnwrap(result.get())

        guard case let .variation(variationMatch) = skuSearchResult else {
            return XCTFail("It didn't provide a product as expected")
        }

        XCTAssertEqual(variationMatch.productVariationID, expectedProductID)
        XCTAssertEqual(variationMatch.productID, expectedParentID)
        XCTAssertEqual(variationMatch.sku, expectedProductSKU)
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_successful_exact_SKU_match_product_but_not_purchasable_then_returns_error() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search-non-purchasable")

        // When
        let productSKU = "chocobars"
        let result = waitFor { promise in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                        sku: productSKU,
                                                                        onCompletion: { product in
                promise(product)
            })
            store.onAction(action)
        }

        let error = try XCTUnwrap(result.failure as? ProductLoadError)
        XCTAssertEqual(result.isFailure, true)
        XCTAssertEqual(error, ProductLoadError.notPurchasable)
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_two_successful_SKU_partial_match_products_then_returns_matched_product() throws {
        // Given
        let remote = MockProductsRemote()
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        remote.whenSearchingProductsBySKU(sku: "chocobars", thenReturn: .success([
            .fake().copy(sku: "chocobars-dark", purchasable: true),
            // The product of the exact SKU match is not the first result.
            .fake().copy(sku: "chocobars", purchasable: true)
        ]))

        // When
        let result = waitFor { promise in
            store.onAction(ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                                  sku: "chocobars",
                                                                                  onCompletion: { product in
                promise(product)
            }))
        }

        let skuSearchResult = try XCTUnwrap(result.get())

        guard case let .product(productMatch) = skuSearchResult else {
            return XCTFail("It didn't provide a product as expected")
        }

        XCTAssertEqual(productMatch.sku, "chocobars")
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_partial_SKU_match_then_returns_not_found_error() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

        // When
        let productSKU = "choco"
        let result = waitFor { promise in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                        sku: productSKU,
                                                                        onCompletion: { product in
                promise(product)
            })
            store.onAction(action)
        }

        let error = try XCTUnwrap(result.failure as? ProductLoadError)
        XCTAssertEqual(result.isFailure, true)
        XCTAssertEqual(error, ProductLoadError.notFound)
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_unsuccessful_SKU_match_then_returns_not_found_error() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

        // When
        let productSKU = "non-existing-product-sku"
        let result = waitFor { promise in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                        sku: productSKU,
                                                                        onCompletion: { product in
                promise(product)
            })
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? ProductLoadError)
        XCTAssertEqual(result.isFailure, true)
        XCTAssertEqual(error, ProductLoadError.notFound)
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_unsuccessful_SKU_match_then_does_not_upsert_product_to_storage() throws {
        // Given
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

        // When
        let nonExistingProductSKU = "non-existing-product-sku"
        let onFailure = waitFor { promise in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID,
                                                                        sku: nonExistingProductSKU,
                                                                        onCompletion: { product in
                promise(false)
            })
            store.onAction(action)
        }

        // Then
        XCTAssertFalse(onFailure)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 0)
    }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_successful_SKU_match_product_then_upserts_product_to_storage() {
         // Given
         let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
         let expectedProductSKU = "chocobars"
         network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

         // Confidence check:
         XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 0)

         // When
         let onSuccess: Bool = waitFor { promise in
             let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID, sku: expectedProductSKU, onCompletion: { product in
                 promise(true)
             })
             store.onAction(action)
         }

         let storedProduct = viewStorage.allObjects(ofType: StorageProduct.self, matching: nil, sortedBy: nil).map { $0 }.first

         // Then
         XCTAssertTrue(onSuccess)
         XCTAssertEqual(viewStorage.countObjects(ofType: StorageProduct.self), 1)
         XCTAssertEqual(storedProduct?.sku, expectedProductSKU)
     }

    func test_retrieveFirstPurchasableItemMatchFromSKU_when_successful_SKU_match_variation_then_upserts_product_to_storage() {
         // Given
         let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
         let expectedProductSKU = "chocobars"
         network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search-variation")

         // Confidence check:
         XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductVariation.self), 0)

         // When
         let onSuccess: Bool = waitFor { promise in
             let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: self.sampleSiteID, sku: expectedProductSKU, onCompletion: { product in
                 promise(true)
             })
             store.onAction(action)
         }

         let storedProduct = viewStorage.allObjects(ofType: StorageProductVariation.self, matching: nil, sortedBy: nil).map { $0 }.first

         // Then
         XCTAssertTrue(onSuccess)
         XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductVariation.self), 1)
         XCTAssertEqual(storedProduct?.sku, expectedProductSKU)
    }

    // MARK: - `generateProductDetails`

    func test_generateProductDetails_returns_product_details_on_success() throws {
        // Given
        // swiftlint:disable:next line_length
        let text = "{\n  \"name\": \"Cheese and Garlic Croutons\",\n  \"description\": \"Enhance your salads.\",\n  \"language\": \"en\"\n}"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(text))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductDetails(siteID: self.sampleSiteID,
                                                                       productName: nil,
                                                                       scannedTexts: [""],
                                                                       language: "en") { result in
                promise(result)
            })
        }

        // Then
        let productDetails = try XCTUnwrap(result.get())
        XCTAssertEqual(productDetails, .init(name: "Cheese and Garlic Croutons",
                                             description: "Enhance your salads."))
    }

    func test_generateProductDetails_returns_error_on_failure() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductDetails(siteID: self.sampleSiteID,
                                                                       productName: nil,
                                                                       scannedTexts: [""],
                                                                       language: "en") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_generateProductDetails_includes_parameters_in_remote_base_parameter() throws {
        // Given
        let scannedTexts = ["onion", "chives"]
        let productName = "food"
        let language = "en"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductDetails(siteID: self.sampleSiteID,
                                                                       productName: productName,
                                                                       scannedTexts: scannedTexts,
                                                                       language: language) { _ in
                promise(())
            })
        }

        // Then
        let base = try XCTUnwrap(generativeContentRemote.generateTextBase)
        let combinedKeywords = scannedTexts + [productName]
        XCTAssertTrue(base.contains("\(combinedKeywords)"))
        XCTAssertTrue(base.contains("\(language)"))
    }

    func test_generateProductDetails_uses_correct_feature() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductDetails(siteID: self.sampleSiteID,
                                                                       productName: nil,
                                                                       scannedTexts: [""],
                                                                       language: "en") { _ in
                promise(())
            })
        }

        // Then
        let feature = try XCTUnwrap(generativeContentRemote.generateTextFeature)
        XCTAssertEqual(feature, GenerativeContentRemoteFeature.productDetailsFromScannedTexts)
    }

    func test_generateProductDetails_uses_correct_response_format() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductDetails(siteID: self.sampleSiteID,
                                                                       productName: nil,
                                                                       scannedTexts: [""],
                                                                       language: "en") { _ in
                promise(())
            })
        }

        // Then
        let format = try XCTUnwrap(generativeContentRemote.generateTextResponseFormat)
        XCTAssertEqual(format, .json)
    }

    // MARK: - `generateProductName`

    func test_generateProductName_returns_product_details_on_success() throws {
        // Given
        let text = "iPhone 15 Smart Phone"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(text))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductName(siteID: 123, keywords: "iPhone 15", language: "en") { result in
                promise(result)
            })
        }

        // Then
        let name = try XCTUnwrap(result.get())
        XCTAssertEqual(name, text)
    }

    func test_generateProductName_returns_error_on_failure() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateProductName(siteID: 123, keywords: "iPhone 15", language: "en") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_generateProductName_includes_parameters_in_remote_base_parameter() throws {
        // Given
        let keyword = "iPhone 15"
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductName(siteID: 123, keywords: keyword, language: "en") { _ in
                promise(())
            })
        }

        // Then
        let base = try XCTUnwrap(generativeContentRemote.generateTextBase)
        XCTAssertTrue(base.contains("\(keyword)"))
    }

    func test_generateProductName_uses_correct_feature() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductName(siteID: 123, keywords: "keyword", language: "en") { _ in
                promise(())
            })
        }

        // Then
        let feature = try XCTUnwrap(generativeContentRemote.generateTextFeature)
        XCTAssertEqual(feature, GenerativeContentRemoteFeature.productName)
    }

    func test_generateProductName_uses_correct_response_format() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingText(thenReturn: .success(""))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        waitFor { promise in
            productStore.onAction(ProductAction.generateProductName(siteID: 123, keywords: "keyword", language: "en") { _ in
                promise(())
            })
        }

        // Then
        let format = try XCTUnwrap(generativeContentRemote.generateTextResponseFormat)
        XCTAssertEqual(format, .text)
    }

    // MARK: - `fetchNumberOfProducts`

    func test_fetchNumberOfProducts_returns_products_total_on_success() throws {
        // Given
        let remote = MockProductsRemote()
        remote.whenLoadingNumberOfProducts(siteID: sampleSiteID, thenReturn: .success(62))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchNumberOfProducts(siteID: self.sampleSiteID) { result in
                promise(result)
            })
        }

        // Then
        let numberOfProducts = try XCTUnwrap(result.get())
        XCTAssertEqual(numberOfProducts, 62)
    }

    func test_fetchNumberOfProducts_returns_error_on_failure() throws {
        // Given
        let remote = MockProductsRemote()
        remote.whenLoadingNumberOfProducts(siteID: sampleSiteID, thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchNumberOfProducts(siteID: self.sampleSiteID) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }


    // MARK: - `generateAIProduct`

    func test_generateAIProduct_returns_AIProduct_on_success() throws {
        // Given
        let product: AIProduct = .fake()
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingAIProduct(thenReturn: .success(product))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateAIProduct(siteID: 123,
                                                                  productName: "Watch",
                                                                  keywords: "Leather strip, silver",
                                                                  language: "en",
                                                                  tone: "Casual",
                                                                  currencySymbol: "INR",
                                                                  dimensionUnit: "cm",
                                                                  weightUnit: "kg",
                                                                  categories: [ProductCategory.fake(), ProductCategory.fake()],
                                                                  tags: [ProductTag.fake(), ProductTag.fake()]) { result in
                promise(result)
            })
        }

        // Then
        let receivedProduct = try XCTUnwrap(result.get())
        XCTAssertEqual(receivedProduct, product)
    }

    func test_generateAIProduct_returns_error_on_failure() throws {
        // Given
        let generativeContentRemote = MockGenerativeContentRemote()
        generativeContentRemote.whenGeneratingAIProduct(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: MockProductsRemote(),
                                        generativeContentRemote: generativeContentRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.generateAIProduct(siteID: 123,
                                                                  productName: "Watch",
                                                                  keywords: "Leather strip, silver",
                                                                  language: "en",
                                                                  tone: "Casual",
                                                                  currencySymbol: "INR",
                                                                  dimensionUnit: "cm",
                                                                  weightUnit: "kg",
                                                                  categories: [ProductCategory.fake(), ProductCategory.fake()],
                                                                  tags: [ProductTag.fake(), ProductTag.fake()]) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetch stock

    func test_fetchStock_returns_stock_on_success() throws {
        // Given
        let stock = ProductStock.fake().copy(siteID: sampleSiteID,
                                             productID: 13,
                                             name: "Steamed bun",
                                             sku: "1353",
                                             manageStock: true,
                                             stockQuantity: 4,
                                             stockStatusKey: "instock")
        let mockRemote = MockProductsRemote()
        mockRemote.whenFetchingStock(thenReturn: .success([stock]))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: mockRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchStockReport(siteID: self.sampleSiteID,
                                                                 stockType: "lowstock",
                                                                 pageNumber: 1,
                                                                 pageSize: 3,
                                                                 order: .descending,
                                                                 completion: { result in
                promise(result)
            }))
        }

        // Then
        let receivedStock = try XCTUnwrap(result.get())
        XCTAssertEqual(receivedStock.count, 1)
        XCTAssertEqual(receivedStock.first, stock)
    }

    func test_fetchStock_returns_error_on_failure() throws {
        // Given
        let mockRemote = MockProductsRemote()
        mockRemote.whenFetchingStock(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: mockRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchStockReport(siteID: self.sampleSiteID,
                                                                 stockType: "lowstock",
                                                                 pageNumber: 1,
                                                                 pageSize: 3,
                                                                 order: .descending,
                                                                 completion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetch product reports

    func test_fetchProductReports_returns_reports_on_success() throws {
        // Given
        let report = ProductReport.fake().copy(productID: 123,
                                               name: "Steamed bun",
                                               imageURL: URL(string: "https://example.com/image.png"),
                                               itemsSold: 3)
        let mockRemote = MockProductsRemote()
        mockRemote.whenFetchingProductReports(thenReturn: .success([report]))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: mockRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchProductReports(siteID: self.sampleSiteID,
                                                                    productIDs: [119, 134],
                                                                    timeZone: .gmt,
                                                                    earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                                    latestDateToInclude: Date(),
                                                                    pageSize: 3,
                                                                    pageNumber: 1,
                                                                    orderBy: .itemsSold,
                                                                    order: .descending) { result in
                promise(result)
            })
        }

        // Then
        let receivedReports = try XCTUnwrap(result.get())
        XCTAssertEqual(receivedReports.count, 1)
        XCTAssertEqual(receivedReports.first, report)
    }

    func test_fetchProductReports_returns_error_on_failure() throws {
        // Given
        let mockRemote = MockProductsRemote()
        mockRemote.whenFetchingProductReports(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: mockRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchProductReports(siteID: self.sampleSiteID,
                                                                    productIDs: [119, 134],
                                                                    timeZone: .gmt,
                                                                    earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                                    latestDateToInclude: Date(),
                                                                    pageSize: 3,
                                                                    pageNumber: 1,
                                                                    orderBy: .itemsSold,
                                                                    order: .descending,
                                                                    completion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Fetch variation reports

    func test_fetchVariationReports_returns_reports_on_success() throws {
        // Given
        let report = ProductReport.fake().copy(productID: 123,
                                               variationID: 133,
                                               name: "Steamed bun",
                                               imageURL: URL(string: "https://example.com/image.png"),
                                               itemsSold: 3)
        let mockRemote = MockProductsRemote()
        mockRemote.whenFetchingVariationReports(thenReturn: .success([report]))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: mockRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchVariationReports(siteID: self.sampleSiteID,
                                                                      productIDs: [119],
                                                                      variationIDs: [120, 122],
                                                                      timeZone: .gmt,
                                                                      earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                                      latestDateToInclude: Date(),
                                                                      pageSize: 3,
                                                                      pageNumber: 1,
                                                                      orderBy: .itemsSold,
                                                                      order: .descending) { result in
                promise(result)
            })
        }

        // Then
        let receivedReports = try XCTUnwrap(result.get())
        XCTAssertEqual(receivedReports.count, 1)
        XCTAssertEqual(receivedReports.first, report)
    }

    func test_fetchVariationReports_returns_error_on_failure() throws {
        // Given
        let mockRemote = MockProductsRemote()
        mockRemote.whenFetchingVariationReports(thenReturn: .failure(NetworkError.timeout()))
        let productStore = ProductStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: mockRemote)

        // When
        let result = waitFor { promise in
            productStore.onAction(ProductAction.fetchVariationReports(siteID: self.sampleSiteID,
                                                                      productIDs: [119],
                                                                      variationIDs: [120, 122],
                                                                      timeZone: .gmt,
                                                                      earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                                      latestDateToInclude: Date(),
                                                                      pageSize: 3,
                                                                      pageNumber: 1,
                                                                      orderBy: .itemsSold,
                                                                      order: .descending) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }
}

// MARK: - Private Helpers
//
private extension ProductStoreTests {

    func sampleProduct(_ siteID: Int64? = nil,
                       name: String? = nil,
                       productID: Int64? = nil,
                       productShippingClass: Networking.ProductShippingClass? = nil,
                       tags: [Networking.ProductTag]? = nil,
                       downloadable: Bool = false,
                       addOns: [Networking.ProductAddOn]? = nil,
                       isSampleItem: Bool = false) -> Networking.Product {
        let testSiteID = siteID ?? sampleSiteID
        let testProductID = productID ?? sampleProductID
        return Product.fake().copy(siteID: testSiteID,
                       productID: testProductID,
                       name: name ?? "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       date: DateFormatter.dateFromString(with: "2019-02-19T17:33:31"),
                       dateCreated: DateFormatter.dateFromString(with: "2019-02-19T17:33:31"),
                       dateModified: DateFormatter.dateFromString(with: "2019-02-19T17:48:01"),
                       dateOnSaleStart: DateFormatter.dateFromString(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: DateFormatter.dateFromString(with: "2019-10-27T21:29:59"),
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
                       menuOrder: 0,
                       addOns: addOns ?? sampleAddOns(),
                       isSampleItem: isSampleItem,
                       bundleStockStatus: .inStock,
                       bundleStockQuantity: nil,
                       bundledItems: [],
                       password: nil,
                       compositeComponents: [],
                       subscription: nil,
                       minAllowedQuantity: nil,
                       maxAllowedQuantity: nil,
                       groupOfQuantity: nil,
                       combineVariationQuantities: nil)
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
                                  dateCreated: DateFormatter.dateFromString(with: "2018-01-26T21:49:45"),
                                  dateModified: DateFormatter.dateFromString(with: "2018-01-26T21:50:11"),
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

        return Product.fake().copy(siteID: testSiteID,
                       productID: sampleProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       date: DateFormatter.dateFromString(with: "2019-02-19T17:33:31"),
                       dateCreated: DateFormatter.dateFromString(with: "2019-02-19T17:33:31"),
                       dateModified: DateFormatter.dateFromString(with: "2019-02-19T17:48:01"),
                       dateOnSaleStart: DateFormatter.dateFromString(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: DateFormatter.dateFromString(with: "2019-10-27T21:29:59"),
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
                       menuOrder: 0,
                       addOns: [],
                       isSampleItem: false,
                       bundleStockStatus: .insufficientStock,
                       bundleStockQuantity: 0,
                       bundledItems: [.fake(), .fake()],
                       compositeComponents: [.fake(), .fake()],
                       subscription: .fake(),
                       minAllowedQuantity: nil,
                       maxAllowedQuantity: nil,
                       groupOfQuantity: nil,
                       combineVariationQuantities: nil)
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
                                  dateCreated: DateFormatter.dateFromString(with: "2018-01-26T21:49:45"),
                                  dateModified: DateFormatter.dateFromString(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        let image2 = ProductImage(imageID: 999,
                                  dateCreated: DateFormatter.dateFromString(with: "2019-01-26T21:44:45"),
                                  dateModified: DateFormatter.dateFromString(with: "2019-01-26T21:54:11"),
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
        return Product.fake().copy(siteID: testSiteID,
                       productID: sampleVariationTypeProductID,
                       name: "Paper Airplane - Black, Long",
                       slug: "paper-airplane-3",
                       permalink: "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Long",
                       date: DateFormatter.dateFromString(with: "2019-04-04T22:06:45"),
                       dateCreated: DateFormatter.dateFromString(with: "2019-04-04T22:06:45"),
                       dateModified: DateFormatter.dateFromString(with: "2019-04-09T20:24:03"),
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
                       menuOrder: 2,
                       addOns: [],
                       isSampleItem: false,
                       bundleStockStatus: nil,
                       bundleStockQuantity: nil,
                       bundledItems: [],
                       compositeComponents: [],
                       subscription: nil,
                       minAllowedQuantity: nil,
                       maxAllowedQuantity: nil,
                       groupOfQuantity: nil,
                       combineVariationQuantities: nil)
    }

    func sampleVariationTypeDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "11", width: "22", height: "33")
    }

    func sampleVariationTypeImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 301,
                                  dateCreated: DateFormatter.dateFromString(with: "2019-04-09T20:23:58"),
                                  dateModified: DateFormatter.dateFromString(with: "2019-04-09T20:23:58"),
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

    func sampleAddOns() -> [Networking.ProductAddOn] {
        let topping = Networking.ProductAddOn.fake().copy(type: .checkbox,
                                                          display: .radioButton,
                                                          name: "Topping",
                                                          titleFormat: .label,
                                                          descriptionEnabled: 1,
                                                          description: "Pizza topping",
                                                          restrictionsType: .any_text,
                                                          priceType: .flatFee,
                                                          options: [
                                                            Networking.ProductAddOnOption.fake().copy(label: "Peperoni", price: "3", priceType: .flatFee),
                                                            Networking.ProductAddOnOption.fake().copy(label: "Extra cheese", price: "4", priceType: .flatFee),
                                                            Networking.ProductAddOnOption.fake().copy(label: "Salami", price: "3", priceType: .flatFee),
                                                            Networking.ProductAddOnOption.fake().copy(label: "Ham", price: "3", priceType: .flatFee)
                                                          ])
        let soda = Networking.ProductAddOn.fake().copy(type: .inputMultiplier,
                                                       display: .dropdown,
                                                       name: "Soda",
                                                       titleFormat: .label,
                                                       position: 1,
                                                       restrictions: 1,
                                                       restrictionsType: .any_text,
                                                       adjustPrice: 1,
                                                       priceType: .quantityBased,
                                                       price: "2",
                                                       max: 3,
                                                       options: [
                                                        Networking.ProductAddOnOption.fake().copy(label: "", price: "", priceType: .flatFee)
                                                       ])
        let delivery = Networking.ProductAddOn.fake().copy(type: .multipleChoice,
                                                           display: .radioButton,
                                                           name: "Delivery",
                                                           titleFormat: .label,
                                                           required: 1,
                                                           position: 2,
                                                           restrictionsType: .any_text,
                                                           options: [
                                                            Networking.ProductAddOnOption.fake().copy(label: "Yes", price: "5", priceType: .flatFee),
                                                            Networking.ProductAddOnOption.fake().copy(label: "No", price: "", priceType: .flatFee)
                                                           ])
        return [topping, soda, delivery]
    }
}

private extension ProductStore {
    convenience init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: ProductsRemoteProtocol) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: remote,
                  generativeContentRemote: MockGenerativeContentRemote())
    }
}
