import XCTest

@testable import Networking
@testable import Storage
@testable import Yosemite

final class ProductVariationStoreTests: XCTestCase {
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
        storageManager = MockupStorageManager()
        network = MockupNetwork()
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
        let imageSource = "https://i0.wp.com/funtestingusa.wpcomstaging.com/wp-content/uploads/2019/11/img_0002-1.jpeg?fit=4288%2C2848&ssl=1"
        return ProductVariation(siteID: sampleSiteID,
                                productID: sampleProductID,
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

    func dateFromGMT(_ dateStringInGMT: String) -> Date {
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        return dateFormatter.date(from: dateStringInGMT)!
    }
}
