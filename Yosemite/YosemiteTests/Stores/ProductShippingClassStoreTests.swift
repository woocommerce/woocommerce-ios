import XCTest

@testable import Networking
@testable import Storage
@testable import Yosemite

final class ProductShippingClassStoreTests: XCTestCase {
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

    // MARK: - ProductShippingClassAction.synchronizeProductShippingClasss

    /// Verifies that `ProductShippingClassAction.synchronizeProductShippingClasss` effectively persists any retrieved ProductShippingClasss.
    ///
    func testRetrieveProductShippingClasssEffectivelyPersisted() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClass list")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "product-shipping-classes-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        let action = ProductShippingClassAction.synchronizeProductShippingClassModels(siteID: sampleSiteID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 3)
            XCTAssertNil(error)

            let sampleProductShippingClassID: Int64 = 94
            let storedProductShippingClass = self.viewStorage.loadProductShippingClass(siteID: self.sampleSiteID, shippingClassID: sampleProductShippingClassID)
            let readOnlyStoredProductShippingClass = storedProductShippingClass?.toReadOnly()
            XCTAssertNotNil(storedProductShippingClass)
            XCTAssertNotNil(readOnlyStoredProductShippingClass)
                                                                            XCTAssertEqual(readOnlyStoredProductShippingClass, self.sampleProductShippingClass(remoteID: sampleProductShippingClassID))

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.synchronizeProductShippingClassModels` multiple times does not create duplicated objects.
    ///
    func testRetrieveProductShippingClasssCreateNoDuplicates() {
        let expectation = self.expectation(description: "Retrieve product shipping class list")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "product-shipping-classes-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        let action = ProductShippingClassAction.synchronizeProductShippingClassModels(siteID: sampleSiteID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let storedProductShippingClasss = self.viewStorage.loadProductShippingClasses(siteID: self.sampleSiteID)
            XCTAssertEqual(storedProductShippingClasss?.count, 3)

            let sampleProductShippingClassID: Int64 = 94
                                                                            let storedProductShippingClass = self.viewStorage.loadProductShippingClass(siteID: self.sampleSiteID, shippingClassID: sampleProductShippingClassID)
            XCTAssertEqual(storedProductShippingClass?.toReadOnly(), self.sampleProductShippingClass(remoteID: sampleProductShippingClassID))

            let action = ProductShippingClassAction.synchronizeProductShippingClassModels(siteID: self.sampleSiteID,
                                                                             pageNumber: self.defaultPageNumber,
                                                                             pageSize: self.defaultPageSize) { error in
                XCTAssertNil(error)

                let storedProductShippingClasss = self.viewStorage.loadProductShippingClasses(siteID: self.sampleSiteID)
                XCTAssertEqual(storedProductShippingClasss?.count, 3)

                // Verifies the expected ProductShippingClass is still correct.
                let sampleProductShippingClassID: Int64 = 94
                let storedProductShippingClass = self.viewStorage.loadProductShippingClass(siteID: self.sampleSiteID, shippingClassID: sampleProductShippingClassID)
                XCTAssertEqual(storedProductShippingClass?.toReadOnly(), self.sampleProductShippingClass(remoteID: sampleProductShippingClassID))

                expectation.fulfill()
            }
            store.onAction(action)
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.synchronizeProductShippingClasss` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveProductShippingClasssReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClasss error response")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "generic_error")

        let action = ProductShippingClassAction.synchronizeProductShippingClassModels(siteID: sampleSiteID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.synchronizeProductShippingClasss` returns an error whenever there is no backend response.
    ///
    func testRetrieveProductShippingClasssReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClasss empty response")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ProductShippingClassAction.synchronizeProductShippingClassModels(siteID: sampleSiteID,
                                                                         pageNumber: defaultPageNumber,
                                                                         pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


private extension ProductShippingClassStoreTests {
    func sampleProductShippingClass(remoteID: Int64) -> Yosemite.ProductShippingClass {
        return ProductShippingClass(shippingClassID: remoteID,
                                    siteID: sampleSiteID,
                                    name: "Free Shipping",
                                    slug: "free-shipping",
                                    descriptionHTML: "Limited offer!",
                                    count: 3)
    }
}
