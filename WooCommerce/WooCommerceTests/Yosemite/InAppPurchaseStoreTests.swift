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

    private var storeKitSession = try! SKTestSession(configurationFileNamed: "WooCommerceTest")

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Product ID
    /// Should match the product ID in WooCommerce.storekit
    ///
    private let sampleProductID: String = "debug.woocommerce.ecommerce.monthly"

    /// Testing Order ID
    /// Should match the order ID in iap-order-create.json
    ///
    private let sampleOrderID: Int64 = 12345

    var store: InAppPurchaseStore!


    override func setUp() {
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = InAppPurchaseStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)
        storeKitSession.disableDialogs = true
    }

    override func tearDown() {
        storeKitSession.resetToDefaultState()
        storeKitSession.clearTransactions()
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

    func test_load_products_loads_products_response() throws {
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
        XCTAssertEqual(products.first?.id, sampleProductID)
    }

    func test_load_products_fails_if_iap_unsupported() throws {
        // Given
        storeKitSession.storefront = "CAN"
        network.simulateResponse(requestUrlSuffix: "iap/products", filename: "iap-products")

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.loadProducts { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        XCTAssert(result.isFailure)
    }

    func test_purchase_product_completes_purchase() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "iap/orders", filename: "iap-order-create")

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.purchaseProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        let purchaseResult = try XCTUnwrap(result.get())
        guard case let .success(verificationResult) = purchaseResult,
              case let .verified(transaction) = verificationResult else {
            return XCTFail()
        }
        XCTAssertEqual(transaction.productID, sampleProductID)
        XCTAssertNotNil(transaction.appAccountToken)
    }

    @available(iOS 16.0, *)
    func test_purchase_product_ensure_xcode_environment() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "iap/orders", filename: "iap-order-create")

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.purchaseProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        let purchaseResult = try XCTUnwrap(result.get())
        guard case let .success(verificationResult) = purchaseResult,
              case let .verified(transaction) = verificationResult else {
            return XCTFail()
        }
        XCTAssertEqual(transaction.environment, .xcode)
    }

    func test_purchase_product_handles_api_errors() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "iap/orders", filename: "error-wp-rest-forbidden")

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.purchaseProduct(siteID: self.sampleSiteID, productID: self.sampleProductID) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        XCTAssert(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssert(error is WordPressApiError)
    }

    // TODO: re-enable the test case when it can pass consistently. More details:
    // https://github.com/woocommerce/woocommerce-ios/pull/8256#pullrequestreview-1199236279
    func test_user_is_entitled_to_product_returns_false_when_not_entitled() throws {
        // Given

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.userIsEntitledToProduct(productID: self.sampleProductID) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        let isEntitled = try XCTUnwrap(result.get())
        XCTAssertFalse(isEntitled)
    }

    // TODO: re-enable the test case when it can pass consistently. More details:
    // https://github.com/woocommerce/woocommerce-ios/pull/8256#pullrequestreview-1199236279
    func test_user_is_entitled_to_product_returns_true_when_entitled() throws {
        // Given
        try storeKitSession.buyProduct(productIdentifier: sampleProductID)

        // When
        let result = waitFor { promise in
            let action = InAppPurchaseAction.userIsEntitledToProduct(productID: self.sampleProductID) { result in
                    promise(result)
                }
            self.store.onAction(action)
        }

        // Then
        let isEntitled = try XCTUnwrap(result.get())
        XCTAssertTrue(isEntitled)
    }
}
