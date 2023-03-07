import XCTest
@testable import Networking


/// InAppPurchasesRemote Unit Tests
///
class InAppPurchasesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    let sampleOrderId: Int = 12345

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that 'moderateComment' as spam properly parses the successful response
    ///
    func test_load_products_returns_list_of_products() throws {
        // Given
        let remote = InAppPurchasesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "iap/products", filename: "iap-products")

        // When
        var result: Result<[String], Error>?
        waitForExpectation { expectation in
            remote.loadProducts() { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        let identifiers = try XCTUnwrap(result?.get())
        XCTAssert(identifiers.count == 1)
    }

    func test_purchase_product_returns_created_order() throws {
        // Given
        let remote = InAppPurchasesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "iap/orders", filename: "iap-order-create")

        // When
        var result: Result<Int, Error>?
        waitForExpectation { expectation in
            remote.createOrder(
                for: sampleSiteID,
                price: 2499,
                productIdentifier: "woocommerce_entry_monthly",
                appStoreCountryCode: "us",
                originalTransactionId: 1234) { aResult in
                    result = aResult
                    expectation.fulfill()
                }
        }

        // Then
        let orderId = try XCTUnwrap(result?.get())
        XCTAssertEqual(sampleOrderId, orderId)
    }
}
