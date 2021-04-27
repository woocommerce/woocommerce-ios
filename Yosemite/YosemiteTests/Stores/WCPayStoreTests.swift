import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite


/// WCPayStore Unit Tests
///
final class WCPayStoreTests: XCTestCase {

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

    /// Verifies that the store hits the network when loading a WCPay Account, and that propagates errors.
    ///
    func test_loadAccount_returns_error_on_failure() throws {
        let store = WCPayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account error response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "generic_error")
        let action = WCPayAction.loadAccount(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isFailure)
            expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when loading a WCPay Account, and that propagates success.
    ///
    func test_loadAccount_returns_expected_data() throws {
        let store = WCPayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-complete")
        let action = WCPayAction.loadAccount(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when capturing a payment ID, and that propagates errors.
    ///
    func test_capturePaymentID_returns_error_on_failure() throws {
        let store = WCPayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Capture Payment Intent error response")
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture", filename: "generic_error")
        let action = WCPayAction.captureOrderPayment(siteID: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     paymentIntentID: samplePaymentIntentID,
                                                     completion: { result in
                                                        XCTAssertTrue(result.isFailure)
                                                        expectation.fulfill()
                                                     })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when capturing a payment ID, and that propagates sucess.
    ///
    func test_capturePaymentID_returns_expected_data() throws {
        let store = WCPayStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
                                 filename: "wcpay-payment-intent-succeeded")
        let action = WCPayAction.captureOrderPayment(siteID: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     paymentIntentID: samplePaymentIntentID,
                                                     completion: { result in
                                                        XCTAssertTrue(result.isSuccess)
                                                        expectation.fulfill()
                                                     })
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
