import XCTest
import TestKit

@testable import Yosemite
@testable import Networking
@testable import Storage

/// PaymentGatewayStore Unit Tests
///
final class PaymentGatewayStoreTests: XCTestCase {

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

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork(useResponseQueue: true)
    }

    func test_synchronize_gateways_correctly_persists_payment_gateways() throws {
        // Given
        let store = PaymentGatewayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list")

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "bacs"))
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "cheque"))
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "paypal"))
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "cod"))
    }

    func test_synchronize_gateways_correctly_deletes_stale_payment_gateways() throws {
        // Given
        let store = PaymentGatewayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list")
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list-half")

        let firstSync = PaymentGatewayAction.synchronizePaymentGateways(siteID: sampleSiteID) { _ in }
        store.onAction(firstSync)

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let secondSync = PaymentGatewayAction.synchronizePaymentGateways(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(secondSync)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "bacs"))
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "cheque"))
        XCTAssertNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "paypal"))
        XCTAssertNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "cod"))
    }
}
