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

    /// Testing ProductShippingClass ID
    ///
    private let sampleShippingClassID: Int64 = 94

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
    func testRetrieveProductShippingClassesEffectivelyPersisted() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClass list")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "product-shipping-classes-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        let action = ProductShippingClassAction
            .synchronizeProductShippingClassModels(siteID: sampleSiteID,
                                                   pageNumber: defaultPageNumber,
                                                   pageSize: defaultPageSize) { error in
                                                    XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 3)
                                                    XCTAssertNil(error)

                                                    let sampleRemoteID: Int64 = 94
                                                    let storedProductShippingClass = self.viewStorage
                                                        .loadProductShippingClass(siteID: self.sampleSiteID,
                                                                                  remoteID: sampleRemoteID)
                                                    let readOnlyStoredProductShippingClass = storedProductShippingClass?.toReadOnly()
                                                    XCTAssertNotNil(storedProductShippingClass)
                                                    XCTAssertNotNil(readOnlyStoredProductShippingClass)
                                                    XCTAssertEqual(readOnlyStoredProductShippingClass,
                                                                   self.sampleProductShippingClass(remoteID: sampleRemoteID))

                                                    expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.synchronizeProductShippingClassModels` multiple times does not create duplicated objects.
    ///
    func testRetrieveProductShippingClassesCreateNoDuplicates() {
        let expectation = self.expectation(description: "Retrieve product shipping class list")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes", filename: "product-shipping-classes-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        let action = ProductShippingClassAction
            .synchronizeProductShippingClassModels(siteID: sampleSiteID,
                                                   pageNumber: defaultPageNumber,
                                                   pageSize: defaultPageSize) { error in
                                                    XCTAssertNil(error)

                                                    let storedProductShippingClasses = self.viewStorage.loadProductShippingClasses(siteID: self.sampleSiteID)
                                                    XCTAssertEqual(storedProductShippingClasses?.count, 3)

                                                    let sampleShippingClassID: Int64 = 94
                                                    let storedProductShippingClass = self.viewStorage
                                                        .loadProductShippingClass(siteID: self.sampleSiteID,
                                                                                  remoteID: sampleShippingClassID)
                                                    XCTAssertEqual(storedProductShippingClass?.toReadOnly(),
                                                                   self.sampleProductShippingClass(remoteID: sampleShippingClassID))

                                                    let action = ProductShippingClassAction
                                                        .synchronizeProductShippingClassModels(siteID: self.sampleSiteID,
                                                                                               pageNumber: self.defaultPageNumber,
                                                                                               pageSize: self.defaultPageSize) { error in
                                                                                                XCTAssertNil(error)

                                                                                                let storedProductShippingClasses = self.viewStorage
                                                                                                    .loadProductShippingClasses(siteID: self.sampleSiteID)
                                                                                                XCTAssertEqual(storedProductShippingClasses?.count, 3)

                                                                                                // Verifies the expected ProductShippingClass is still correct.
                                                                                                let sampleShippingClassID: Int64 = 94
                                                                                                let storedProductShippingClass = self.viewStorage
                                                                                                    .loadProductShippingClass(siteID: self.sampleSiteID,
                                                                                                                              remoteID: sampleShippingClassID)
                                                                                                XCTAssertEqual(storedProductShippingClass?.toReadOnly(),
                                                                                                               self.sampleProductShippingClass(remoteID:
                                                                                                                sampleShippingClassID))

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

    // MARK: - ProductShippingClassAction.retrieveProductShippingClass

    /// Verifies that `ProductShippingClassAction.retrieveProductShippingClass` effectively persists any retrieved ProductShippingClasss.
    ///
    func testRetrieveProductShippingClassEffectivelyPersisted() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClass")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes/\(sampleShippingClassID)", filename: "product-shipping-classes-load-one")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        let product = MockProduct().product(siteID: sampleSiteID, shippingClassID: sampleShippingClassID)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        let action = ProductShippingClassAction
            .retrieveProductShippingClass(siteID: sampleSiteID, remoteID: sampleShippingClassID) { (shippingClass, error) in
                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 1)
                XCTAssertNil(error)

                let storedProductShippingClass = self.viewStorage
                    .loadProductShippingClass(siteID: self.sampleSiteID,
                                              remoteID: self.sampleShippingClassID)
                let readOnlyStoredProductShippingClass = storedProductShippingClass?.toReadOnly()
                XCTAssertNotNil(storedProductShippingClass)
                XCTAssertNotNil(readOnlyStoredProductShippingClass)
                XCTAssertEqual(readOnlyStoredProductShippingClass,
                               self.sampleProductShippingClass(remoteID: self.sampleShippingClassID))

                expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.retrieveProductShippingClass` multiple times does not create duplicated objects.
    ///
    func testRetrieveProductShippingClassCreateNoDuplicates() {
        let expectation = self.expectation(description: "Retrieve product shipping class")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes/\(sampleShippingClassID)",
            filename: "product-shipping-classes-load-one")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductShippingClass.self), 0)

        let product = MockProduct().product(siteID: sampleSiteID, shippingClassID: sampleShippingClassID)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        let action = ProductShippingClassAction
            .retrieveProductShippingClass(siteID: sampleSiteID, remoteID: sampleShippingClassID) { (shippingClass, error) in
                XCTAssertNil(error)

                let storedProductShippingClasses = self.viewStorage.loadProductShippingClasses(siteID: self.sampleSiteID)
                XCTAssertEqual(storedProductShippingClasses?.count, 1)

                let action = ProductShippingClassAction
                    .retrieveProductShippingClass(siteID: self.sampleSiteID, remoteID: self.sampleShippingClassID) { (model, error) in
                        XCTAssertNil(error)

                        let storedProductShippingClasses = self.viewStorage
                            .loadProductShippingClasses(siteID: self.sampleSiteID)
                        XCTAssertEqual(storedProductShippingClasses?.count, 1)

                        expectation.fulfill()
                }
                store.onAction(action)
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.retrieveProductShippingClass` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveProductShippingClassReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClass error response")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products/shipping_classes/\(sampleShippingClassID)", filename: "generic_error")

        let product = MockProduct().product(siteID: sampleSiteID, shippingClassID: sampleShippingClassID)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        let action = ProductShippingClassAction.retrieveProductShippingClass(siteID: sampleSiteID, remoteID: sampleShippingClassID) { (model, error) in
            XCTAssertNil(model)
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductShippingClassAction.retrieveProductShippingClass` returns an error whenever there is no backend response.
    ///
    func testRetrieveProductShippingClassReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve ProductShippingClass empty response")
        let store = ProductShippingClassStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let product = MockProduct().product(siteID: sampleSiteID, shippingClassID: sampleShippingClassID)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        let action = ProductShippingClassAction.retrieveProductShippingClass(siteID: sampleSiteID, remoteID: sampleShippingClassID) { (model, error) in
            XCTAssertNil(model)
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


private extension ProductShippingClassStoreTests {
    func sampleProductShippingClass(remoteID: Int64) -> Yosemite.ProductShippingClass {
        return ProductShippingClass(count: 3,
                                    descriptionHTML: "Limited offer!",
                                    name: "Free Shipping",
                                    shippingClassID: remoteID,
                                    siteID: sampleSiteID,
                                    slug: "free-shipping")
    }
}
