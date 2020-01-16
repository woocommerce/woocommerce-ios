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

        let action = ProductAction.validateProductSKU("", siteID: sampleSiteID) { isValid in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        }

        productStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that an existing SKU is not valid.
    func testValidatingSKUWithExistingValue() {
        let expectation = self.expectation(description: "Product SKU validation")
        let store = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "products", filename: "product-search-sku")

        let expectedResult = false

        let skuToSearchFor = "T-SHIRT-HAPPY-NINJA"
        let action = ProductAction.validateProductSKU(skuToSearchFor, siteID: sampleSiteID) { isValid in
            XCTAssertEqual(isValid, expectedResult)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
