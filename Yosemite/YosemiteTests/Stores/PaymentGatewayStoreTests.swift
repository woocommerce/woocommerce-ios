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

    /// Convenience: returns the number of stored payment gateways
    ///
    private var storedPaymentGatewaysCount: Int {
        return viewStorage.countObjects(ofType: StoragePaymentGateway.self)
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    /// Store
    ///
    private var store: PaymentGatewayStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork(useResponseQueue: true)
        store = PaymentGatewayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    func test_synchronize_gateways_correctly_persists_payment_gateways() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
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
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list")
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list-half")

        let firstSync = PaymentGatewayAction.synchronizePaymentGateways(siteID: sampleSiteID) { _ in }
        store.onAction(firstSync)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let secondSync = PaymentGatewayAction.synchronizePaymentGateways(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(secondSync)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "bacs"))
        XCTAssertNotNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "cheque"))
        XCTAssertNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "paypal"))
        XCTAssertNil(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: "cod"))
    }

    func test_updatePaymentGateway_returns_network_error_on_failure() {
        // Given
        let samplePaymentGatewayID = "cod"
        let samplePaymentGateway = PaymentGateway.fake().copy(siteID: sampleSiteID,
                                                              gatewayID: samplePaymentGatewayID,
                                                              title: "Failing gateway",
                                                              enabled: false)
        storePaymentGateway(samplePaymentGateway, for: sampleSiteID)
        assertEqual(1, storedPaymentGatewaysCount)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "payment_gateways/\(samplePaymentGatewayID)", error: expectedError)

        // When
        let updatedPaymentGateway = samplePaymentGateway.copy(title: "Cash on delivery")
        let result: Result<Networking.PaymentGateway, Error> = waitFor { promise in
            let action = PaymentGatewayAction.updatePaymentGateway(updatedPaymentGateway) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
        assertEqual(1, storedPaymentGatewaysCount)
        assertEqual("Failing gateway", viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: samplePaymentGatewayID)?.title)
    }

    func test_updatePaymentGateway_updates_stored_paymentGateway_upon_success() throws {
        // Given
        let samplePaymentGatewayID = "cod"
        let samplePaymentGateway = PaymentGateway.fake().copy(siteID: sampleSiteID,
                                                              gatewayID: samplePaymentGatewayID,
                                                              title: "Old title",
                                                              enabled: false)

        storePaymentGateway(samplePaymentGateway, for: sampleSiteID)
        assertEqual(1, storedPaymentGatewaysCount)

        network.simulateResponse(requestUrlSuffix: "payment_gateways/\(samplePaymentGatewayID)", filename: "payment-gateway-cod")

        // When
        let updatedPaymentGateway = samplePaymentGateway.copy(enabled: true)
        let result: Result<Networking.PaymentGateway, Error> = waitFor { promise in
            let action: PaymentGatewayAction
            action = .updatePaymentGateway(updatedPaymentGateway) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let storedPaymentGateway = try XCTUnwrap(viewStorage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: samplePaymentGatewayID))
        assertEqual("Cash on delivery", storedPaymentGateway.title)
        XCTAssertTrue(storedPaymentGateway.enabled)
    }
}

private extension PaymentGatewayStoreTests {
    @discardableResult
    func storePaymentGateway(_ paymentGateway: Networking.PaymentGateway, for siteID: Int64) -> Storage.PaymentGateway {
        let storedPaymentGateway = viewStorage.insertNewObject(ofType: PaymentGateway.self)
        storedPaymentGateway.update(with: paymentGateway)
        storedPaymentGateway.siteID = siteID
        return storedPaymentGateway
    }
}
