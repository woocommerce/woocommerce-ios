import XCTest
import TestKit

@testable import Yosemite
@testable import Networking
@testable import Storage

/// PaymentGatewayStore Unit Tests
///
final class PaymentGatewayAccountStoreTests: XCTestCase {

    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 999

    /// Testing OrderID
    ///
    private let sampleOrderID: Int64 = 560

    /// Testing PaymentIntentID
    ///
    private let samplePaymentIntentID: String = "p_idREDACTED"

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Tests

    /// Verifies that the PaymentGatewayAccountStore hits the network when loading a WCPay Account, propagates errors and places nothing in storage.
    ///
    func test_loadAccounts_returns_error_on_failure() throws {
        let store = PaymentGatewayAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account error response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "generic_error")

        let action = PaymentGatewayAccountAction.loadAccounts(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isFailure)
            expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        XCTAssertNil(viewStorage.firstObject(ofType: Storage.PaymentGatewayAccount.self, matching: nil))
    }

    /// Verifies that the PaymentGatewayAccountStore hits the network when loading a WCPay Account, propagates success and upserts the account into storage.
    ///
    func test_loadAccounts_returns_expected_data() throws {
        let store = PaymentGatewayAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-complete")
        let action = PaymentGatewayAccountAction.loadAccounts(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        XCTAssert(viewStorage.countObjects(ofType: Storage.PaymentGatewayAccount.self, matching: nil) == 1)

        let storageAccount = viewStorage.loadPaymentGatewayAccount(
            siteID: sampleSiteID,
            gatewayID: WCPayAccount.gatewayID
        )

        XCTAssert(storageAccount?.siteID == sampleSiteID)
        XCTAssert(storageAccount?.gatewayID == WCPayAccount.gatewayID)
        XCTAssert(storageAccount?.status == "complete")
    }

    /// Verifies that the store hits the network when capturing a payment ID, and that propagates errors.
    ///
    func test_capturePaymentID_returns_error_on_failure() throws {
        let store = PaymentGatewayAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Capture Payment Intent error response")
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment", filename: "generic_error")
        let action = PaymentGatewayAccountAction.captureOrderPayment(siteID: sampleSiteID,
                                                                     orderID: sampleOrderID,
                                                                     paymentIntentID: samplePaymentIntentID,
                                                                     completion: { result in
                                                                        XCTAssertTrue(result.isFailure)
                                                                        expectation.fulfill()
                                                                     })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when capturing a payment ID, and that propagates success.
    ///
    func test_capturePaymentID_returns_expected_data() throws {
        let store = PaymentGatewayAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-succeeded")
        let action = PaymentGatewayAccountAction.captureOrderPayment(siteID: sampleSiteID,
                                                                     orderID: sampleOrderID,
                                                                     paymentIntentID: samplePaymentIntentID,
                                                                     completion: { result in
                                                                        XCTAssertTrue(result.isSuccess)
                                                                        expectation.fulfill()
                                                                     })
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when fetching a customer for an order, and propagates success.
    ///
    func test_fetchOrderCustomer_returns_expected_data() {
        let store = PaymentGatewayAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
                                 filename: "wcpay-customer")
        let action = PaymentGatewayAccountAction.fetchOrderCustomer(siteID: sampleSiteID,
                                                                    orderID: sampleOrderID,
                                                                    onCompletion: { result in
                                                                        XCTAssertTrue(result.isSuccess)
                                                                        if case .success(let customer) = result {
                                                                            XCTAssertEqual(customer.id, "cus_0123456789abcd")
                                                                            expectation.fulfill()
                                                                        }
                                                                    })
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when fetching a customer for an order, and propagates errors.
    ///
    func test_fetchOrderCustomer_returns_error_on_failure() {
        let store = PaymentGatewayAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
                                 filename: "wcpay-customer-error")
        let action = PaymentGatewayAccountAction.fetchOrderCustomer(siteID: sampleSiteID,
                                                                    orderID: sampleOrderID,
                                                                    onCompletion: { result in
                                                                        XCTAssertTrue(result.isFailure)
                                                                        expectation.fulfill()
                                                                    })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
