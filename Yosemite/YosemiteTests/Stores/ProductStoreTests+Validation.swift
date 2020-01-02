import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

final class ProductStoreTests_Validation: XCTestCase {
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

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: test cases for `ProductAction.validateProductSKU`

    /// Verifies that a nil SKU is valid.
    func testValidatingSKUWithNilValue() {
        let expectation = self.expectation(description: "Product SKU validation")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Inserts a sample Product into storage with nil sku.
        let sampleProduct = MockProduct().product(siteID: sampleSiteID, productID: 1, sku: nil)
        storageManager.insertSampleProduct(readOnlyProduct: sampleProduct)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        let action = ProductAction.validateProductSKU(nil, siteID: sampleSiteID) { isValid in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that an empty SKU is valid.
    func testValidatingSKUWithEmptyValue() {
        let expectation = self.expectation(description: "Product SKU validation")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Inserts a sample Product into storage with nil sku.
        let sampleProduct = MockProduct().product(siteID: sampleSiteID, productID: 1, sku: "")
        storageManager.insertSampleProduct(readOnlyProduct: sampleProduct)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        let action = ProductAction.validateProductSKU("", siteID: sampleSiteID) { isValid in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that a duplicated SKU is invalid.
    func testValidatingSKUWithAnExistingValue() {
        let expectation = self.expectation(description: "Product SKU validation")
        let productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Inserts a sample Product into storage with nil sku.
        let sku = "uks"
        let sampleProduct = MockProduct().product(siteID: sampleSiteID, productID: 1, sku: sku)
        storageManager.insertSampleProduct(readOnlyProduct: sampleProduct)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Product.self), 1)

        let action = ProductAction.validateProductSKU(sku, siteID: sampleSiteID) { isValid in
            XCTAssertFalse(isValid)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
