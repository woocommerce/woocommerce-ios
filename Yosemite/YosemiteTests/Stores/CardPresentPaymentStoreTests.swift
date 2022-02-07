import XCTest
import Fakes
@testable import Yosemite
@testable import Networking
@testable import Storage
@testable import Hardware

/// CardPresentPaymentStore Unit Tests
///
/// All mock properties are necessary because
/// CardPresentPaymentStore extends Store.
final class CardPresentPaymentStoreTests: XCTestCase {
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

    /// Mock Card Reader Service: In memory
    private var mockCardReaderService: MockCardReaderService!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Testing OrderID
    ///
    private let sampleOrderID: Int64 = 560

    /// Testing Charge ID
    ///
    private let sampleChargeID = "ch_3KMVap2EdyGr1FMV1uKJEWtg"

    /// Testing Charge ID for error
    ///
    private let sampleErrorChargeID = "ch_3KMVapErrorERROR"

    /// Testing PaymentIntentID
    ///
    private let samplePaymentIntentID: String = "p_idREDACTED"

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        mockCardReaderService = MockCardReaderService()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        mockCardReaderService = nil

        super.tearDown()
    }

    // MARK: - CardPresentPaymentAction.startCardReaderDiscovery

    /// Verifies that CardPresentPaymentAction.startCardReaderDiscovery hits the `start` method in the service.
    ///
    func test_start_discovery_action_hits_start_in_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID, onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitStart)
    }

    func test_start_discovery_action_returns_data_eventually() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let expectation = self.expectation(description: "Readers discovered")

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            onReaderDiscovered: { _ in
                expectation.fulfill()
            },
            onError: { _ in }
        )

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_start_discovery_action_passes_configuraton_provider_to_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID, onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didReceiveAConfigurationProvider)
    }

    /// This test is meant to cover the error when there is a failure to fetch
    /// the connection token
    /// We do not have proper error handling for now, but it is in the pipeline
    /// https://github.com/woocommerce/woocommerce-ios/issues/3734
    /// https://github.com/woocommerce/woocommerce-ios/issues/3741
    /// This test will be edited to assert an error was received when
    /// proper error support is implemented. 
    func test_start_discovery_action_returns_empty_error_when_token_fetching_fails() {
        let expectation = self.expectation(description: "Empty readers on failure to obtain a connection token")

        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        network.simulateResponse(requestUrlSuffix: "payments/connection_tokens", filename: "generic_error")

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            onReaderDiscovered: { discoveredReaders in
                XCTAssertTrue(self.mockCardReaderService.didReceiveAConfigurationProvider)
                if discoveredReaders.count == 0 {
                    expectation.fulfill()
                }
            },
            onError: { _ in }
        )

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_cancel_discovery_action_hits_cancel_in_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            //
        }

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitCancel)
    }

    /// We are still not handling errors, so we will need a new test here
    /// for the case when cancelation fails, which apparently is a thing
    func test_cancel_discovery_action_publishes_idle_as_new_discovery_status() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let expectation = self.expectation(description: "Cancelling discovery published idle as discoveryStatus")

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            if result.isSuccess {
                expectation.fulfill()
            }
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_cancel_discovery_after_start_rdpchanges_discovery_status_to_idle_eventually() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let expectation = self.expectation(description: "Cancelling discovery changes discoveryStatus to idle")

        let startDiscoveryAction = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID, onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(startDiscoveryAction)

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            print("=== hitting cancellation completion")
            if result.isSuccess {
                expectation.fulfill()
            }
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_connect_to_reader_action_updates_returns_provided_reader_on_success() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let expectation = self.expectation(description: "Connect to card reader")

        let reader = MockCardReader.bbposChipper2XBT()
        let action = CardPresentPaymentAction.connect(reader: reader) { result in
            switch result {
            case .failure:
                XCTFail()
            case .success(let connectedReader):
                XCTAssertEqual(connectedReader, reader)

                expectation.fulfill()
            }
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_disconnect_action_hits_disconnect_in_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService,
                                                       allowStripeIPP: false)

        let action = CardPresentPaymentAction.disconnect(onCompletion: { result in
            //
        })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitDisconnect)
    }

    /// Verifies that the PaymentGatewayAccountStore hits the network when loading a WCPay Account and places nothing in storage in case of error.
    ///
    func test_loadAccounts_handles_failure() throws {
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)
        let expectation = self.expectation(description: "Load Account error response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts",
                                 filename: "generic_error")
        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary",
                                 filename: "generic_error")

        let action = CardPresentPaymentAction.loadAccounts(siteID: sampleSiteID, onCompletion: { result in
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
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts",
                                 filename: "wcpay-account-complete")
        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary",
                                 filename: "stripe-account-complete")
        let action = CardPresentPaymentAction.loadAccounts(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        XCTAssert(viewStorage.countObjects(ofType: Storage.PaymentGatewayAccount.self, matching: nil) == 2)

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
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)
        let expectation = self.expectation(description: "Capture Payment Intent error response")
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment", filename: "generic_error")
        let action = CardPresentPaymentAction.captureOrderPayment(siteID: sampleSiteID,
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
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-succeeded")
        let action = CardPresentPaymentAction.captureOrderPayment(siteID: sampleSiteID,
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
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
                                 filename: "wcpay-customer")
        let action = CardPresentPaymentAction.fetchOrderCustomer(siteID: sampleSiteID,
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
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)
        let expectation = self.expectation(description: #function)
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
                                 filename: "wcpay-customer-error")
        let action = CardPresentPaymentAction.fetchOrderCustomer(siteID: sampleSiteID,
                                                                    orderID: sampleOrderID,
                                                                    onCompletion: { result in
                                                                        XCTAssertTrue(result.isFailure)
                                                                        expectation.fulfill()
                                                                    })

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the store hits the network when fetching a charge, and propagates success.
    ///
    func test_fetchWCPayCharge_returns_expected_data() throws {
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)

        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleChargeID)",
                                 filename: "wcpay-charge-card-present")

        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleChargeID, onCompletion: { result in
                promise(result)
            })
            store.onAction(action)
        }
        XCTAssertTrue(result.isSuccess)
        let charge = try XCTUnwrap(result).get()
        XCTAssertEqual(charge.id, sampleChargeID)
    }

    /// Verifies that the store hits the network when fetching a charge, and propagates errors.
    ///
    func test_fetchWCPayCharge_returns_error_on_failure() {
        let store = CardPresentPaymentStore(dispatcher: dispatcher,
                                            storageManager: storageManager,
                                            network: network,
                                            cardReaderService: mockCardReaderService,
                                            allowStripeIPP: false)

        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleErrorChargeID)",
                                 filename: "wcpay-customer-error")
        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleErrorChargeID, onCompletion: { result in
                promise(result)
            })
            store.onAction(action)
        }
        XCTAssertTrue(result.isFailure)
    }
}
