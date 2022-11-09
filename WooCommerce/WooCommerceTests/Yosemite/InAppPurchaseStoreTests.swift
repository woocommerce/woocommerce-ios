import XCTest
import TestKit
import StoreKitTest

@testable import Yosemite
@testable import Networking

final class InAppPurchaseStoreTests: XCTestCase {

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    private var storeKitSession = try! SKTestSession(configurationFileNamed: "WooCommerce")

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    var store: InAppPurchaseStore!


    override func setUp() {
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = InAppPurchaseStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)
        storeKitSession.disableDialogs = true
    }

    override func tearDown() {
        storeKitSession.resetToDefaultState()
    }

    func test_iap_supported_in_us() throws {
        // Given
        storeKitSession.storefront = "USA"

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.inAppPurchasesAreSupported { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_iap_supported_in_canada() throws {
        // Given
        storeKitSession.storefront = "CAN"

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.inAppPurchasesAreSupported { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_load_products_loads_empty_products_response() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "iap/products", filename: "iap-products")

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.loadProducts { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        let products = try XCTUnwrap(result.get())
        XCTAssertFalse(products.isEmpty)
    }
}
