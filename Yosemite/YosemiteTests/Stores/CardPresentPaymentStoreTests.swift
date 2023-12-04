import Combine
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

    private var mockCardReaderConfigProvider: CommonReaderConfigProviding!

    private var cardPresentStore: CardPresentPaymentStore!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Testing OrderID
    ///
    private let sampleOrderID: Int64 = 560

    /// Testing Charge ID
    ///
    private let sampleChargeID = "ch_3KMVap2EdyGr1FMV1uKJEWtg"

    /// Testing Charge ID for interac transaction
    ///
    private let sampleInteracChargeID = "ch_3KdC1s2ETjwGHy9P0Cawro7o"

    /// Testing Charge ID for card transaction
    ///
    private let sampleCardChargeID = "ch_3KMuym2EdyGr1FMV0uQZeFqm"

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
        mockCardReaderConfigProvider = MockCommonReaderConfigProviding()
        cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                   storageManager: storageManager,
                                                   network: network,
                                                   cardReaderService: mockCardReaderService,
                                                   cardReaderConfigProvider: mockCardReaderConfigProvider)
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
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            discoveryMethod: .bluetoothScan,
            onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitStart)
    }

    func test_start_discovery_action_returns_data_eventually() {
        let expectation = self.expectation(description: "Readers discovered")

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            discoveryMethod: .bluetoothScan,
            onReaderDiscovered: { _ in
                expectation.fulfill()
            },
            onError: { _ in }
        )

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_start_discovery_action_passes_configuration_provider_to_service() {
        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID,
                                                                       discoveryMethod: .bluetoothScan,
                                                                       onReaderDiscovered: { _ in },
                                                                       onError: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didReceiveAConfigurationProvider)
    }

    func test_start_discovery_action_passes_discovery_method_to_service() {
        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID,
                                                                       discoveryMethod: .bluetoothScan,
                                                                       onReaderDiscovered: { _ in },
                                                                       onError: { _ in })

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

        network.simulateResponse(requestUrlSuffix: "payments/connection_tokens", filename: "generic_error")

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            discoveryMethod: .bluetoothScan,
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
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            //
        }

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitCancel)
    }

    /// We are still not handling errors, so we will need a new test here
    /// for the case when cancelation fails, which apparently is a thing
    func test_cancel_discovery_action_publishes_idle_as_new_discovery_status() {
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
        let expectation = self.expectation(description: "Cancelling discovery changes discoveryStatus to idle")

        let startDiscoveryAction = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            discoveryMethod: .bluetoothScan,
            onReaderDiscovered: { _ in },
            onError: { _ in })

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
        let action = CardPresentPaymentAction.disconnect(onCompletion: { result in
            //
        })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitDisconnect)
    }

    /// Verifies that the PaymentGatewayAccountStore hits the network when loading a WCPay Account and places nothing in storage in case of error.
    ///
    func test_loadAccounts_handles_failure() throws {
        let expectation = self.expectation(description: "Load Account error response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts",
                                 filename: "generic_error")
        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary",
                                 filename: "generic_error")

        let action = CardPresentPaymentAction.loadAccounts(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isFailure)
            expectation.fulfill()
        })

        cardPresentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        XCTAssertNil(viewStorage.firstObject(ofType: Storage.PaymentGatewayAccount.self, matching: nil))
    }

    /// Verifies that the PaymentGatewayAccountStore hits the network when loading a WCPay Account, propagates success and upserts the account into storage.
    ///
    func test_loadAccounts_returns_expected_data() throws {
        let expectation = self.expectation(description: "Load Account fetch response")
        network.simulateResponse(requestUrlSuffix: "payments/accounts",
                                 filename: "wcpay-account-complete")
        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary",
                                 filename: "stripe-account-complete")
        let action = CardPresentPaymentAction.loadAccounts(siteID: sampleSiteID, onCompletion: { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        })

        cardPresentStore.onAction(action)
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

    /// Verifies that the store hits the network when fetching a charge, and propagates success.
    ///
    func test_fetchWCPayCharge_returns_expected_data() throws {
        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleChargeID)",
                                 filename: "wcpay-charge-card-present")

        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertTrue(result.isSuccess)
        let charge = try XCTUnwrap(result).get()
        XCTAssertEqual(charge.id, sampleChargeID)
    }

    func test_fetchWCPayCharge_inserts_charge_in_storage() throws {
        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleChargeID)",
                                 filename: "wcpay-charge-card-present")

        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertTrue(result.isSuccess)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil) == 1)

        let storageCharge = viewStorage.loadWCPayCharge(siteID: sampleSiteID, chargeID: sampleChargeID)

        XCTAssertEqual(storageCharge?.siteID, sampleSiteID)
        XCTAssertEqual(storageCharge?.chargeID, sampleChargeID)
        XCTAssertEqual(storageCharge?.status, "succeeded")
    }

    func test_fetchWCPayCharge_inserts_card_present_charge_details_in_storage() throws {
        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleChargeID)",
                                 filename: "wcpay-charge-card-present")

        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertTrue(result.isSuccess)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil) == 1)

        let storageCharge = viewStorage.loadWCPayCharge(siteID: sampleSiteID, chargeID: sampleChargeID)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPaymentDetails.self, matching: nil) == 0)
        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPresentPaymentDetails.self, matching: nil) == 1)
        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPresentReceiptDetails.self, matching: nil) == 1)

        let storedDetails = storageCharge?.cardPresentDetails
        XCTAssertEqual(storedDetails?.receipt?.applicationPreferredName, "Stripe Credit")
        XCTAssertEqual(storedDetails?.last4, "9969")
        XCTAssertNil(storageCharge?.cardDetails)
    }

    func test_fetchWCPayCharge_inserts_card_charge_details_in_storage() throws {
        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleCardChargeID)",
                                 filename: "wcpay-charge-card")

        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleCardChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertTrue(result.isSuccess)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil) == 1)

        let storageCharge = viewStorage.loadWCPayCharge(siteID: sampleSiteID, chargeID: sampleCardChargeID)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPaymentDetails.self, matching: nil) == 1)
        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPresentPaymentDetails.self, matching: nil) == 0)
        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPresentReceiptDetails.self, matching: nil) == 0)

        let storedDetails = storageCharge?.cardDetails
        XCTAssertEqual(storedDetails?.last4, "1111")
        XCTAssertNil(storageCharge?.cardPresentDetails)
    }

    func test_fetchWCPayCharge_inserts_interac_present_charge_details_in_storage() throws {
        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleInteracChargeID)",
                                 filename: "wcpay-charge-interac-present")

        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleInteracChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertTrue(result.isSuccess)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil) == 1)

        let storageCharge = viewStorage.loadWCPayCharge(siteID: sampleSiteID, chargeID: sampleInteracChargeID)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPaymentDetails.self, matching: nil) == 0)
        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPresentPaymentDetails.self, matching: nil) == 1)
        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCardPresentReceiptDetails.self, matching: nil) == 1)

        let storedDetails = storageCharge?.cardPresentDetails
        XCTAssertEqual(storedDetails?.receipt?.applicationPreferredName, "Interac")
        XCTAssertEqual(storedDetails?.last4, "1933")
        XCTAssertNil(storageCharge?.cardDetails)
    }

    /// Verifies that the store hits the network when fetching a charge, and propagates errors.
    ///
    func test_fetchWCPayCharge_returns_error_on_failure() {
        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleErrorChargeID)",
                                 filename: "wcpay-charge-error")
        let result: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleErrorChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that the store deletes the charge if it's gone from the remote.
    ///
    func test_fetchWCPayCharge_deletes_existing_charge_on_no_such_charge_failure() {
        let charge = viewStorage.insertNewObject(ofType: Storage.WCPayCharge.self)
        let networkCharge = WCPayCharge.fake().copy(siteID: sampleSiteID, id: sampleErrorChargeID)
        charge.update(with: networkCharge)
        let otherCharge = viewStorage.insertNewObject(ofType: Storage.WCPayCharge.self)
        let otherNetworkCharge = WCPayCharge.fake().copy(siteID: sampleSiteID, id: sampleChargeID)
        otherCharge.update(with: otherNetworkCharge)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil) == 2)

        network.simulateResponse(requestUrlSuffix: "payments/charges/\(sampleErrorChargeID)",
                                 filename: "wcpay-charge-error")
        let _: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleErrorChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil), 1)

        let storageCharge = viewStorage.firstObject(ofType: Storage.WCPayCharge.self)
        XCTAssertEqual(storageCharge, otherCharge)
    }

    /// Verifies that the store doesn't delete charges just for any old error.
    ///
    func test_fetchWCPayCharge_does_not_delete_existing_charge_on_unknown_failure() {
        let charge = viewStorage.insertNewObject(ofType: Storage.WCPayCharge.self)
        let networkCharge = WCPayCharge.fake().copy(siteID: sampleSiteID, id: sampleErrorChargeID)
        charge.update(with: networkCharge)
        let otherCharge = viewStorage.insertNewObject(ofType: Storage.WCPayCharge.self)
        let otherNetworkCharge = WCPayCharge.fake().copy(siteID: sampleSiteID, id: sampleChargeID)
        otherCharge.update(with: otherNetworkCharge)

        XCTAssert(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil) == 2)

        network.simulateError(requestUrlSuffix: "payments/charges/\(sampleErrorChargeID)",
                              error: DotcomError.unknown(code: "beep", message: "boop"))

        let _: Result<Yosemite.WCPayCharge, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: self.sampleSiteID, chargeID: self.sampleErrorChargeID, onCompletion: { result in
                promise(result)
            })
            cardPresentStore.onAction(action)
        }
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.WCPayCharge.self, matching: nil), 2)
    }

    // MARK: - `collectPayment`

    /// Verifies that  only `onProcessingCompletion` is called after card reader finishes capturing payment, since card has to be removed before
    /// `onCompletion` is called.
    ///
    func test_collectPayment_calls_onProcessingCompletion_but_not_onCompletion_after_card_reader_capturePayment_success() {
        // Given
        let intent = PaymentIntent.fake()
        mockCardReaderService.whenCapturingPayment(thenReturn: Just(intent)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher())
        mockCardReaderService.whenWaitForInsertedCardToBeRemoved(thenReturn: Future<Void, Never> { promise in
            // Card is not removed.
        })

        // When
        let processedIntent: PaymentIntent = waitFor { [self] promise in
            let action = CardPresentPaymentAction
                .collectPayment(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                parameters: .init(amount: 2.5, currency: "USD", stripeSmallestCurrencyUnitMultiplier: 100)) { cardReaderEvent in

                } onProcessingCompletion: { intent in
                    promise(intent)
                } onCompletion: { result in
                    XCTFail("Payment collection is not complete until the card removal step completes.")
                }
            cardPresentStore.onAction(action)
        }

        // Then
        XCTAssertEqual(processedIntent.id, intent.id)
        XCTAssertEqual(processedIntent.status, intent.status)
    }

    /// Verifies that `onCompletion` is called after card reader finishes capturing payment, then the card is removed successfully
    /// and the site finishes capturing payment.
    ///
    func test_collectPayment_calls_onCompletion_after_card_reader_capturePayment_success_and_card_removal_and_site_capturePayment() throws {
        // Given
        let intent = PaymentIntent.fake()
        mockCardReaderService.whenCapturingPayment(thenReturn: Just(intent)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher())
        mockCardReaderService.whenWaitForInsertedCardToBeRemoved(thenReturn: Future<Void, Never> { promise in
            promise(.success(()))
        })
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-succeeded")

        // When
        let result: Result<PaymentIntent, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction
                .collectPayment(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                parameters: .init(amount: 2.5, currency: "USD", stripeSmallestCurrencyUnitMultiplier: 100)) { cardReaderEvent in
                } onProcessingCompletion: { intent in
                } onCompletion: { result in
                    promise(result)
                }
            cardPresentStore.onAction(action)
        }

        // Then
        let finalIntent = try XCTUnwrap(result.get())
        XCTAssertEqual(finalIntent.id, intent.id)
        XCTAssertEqual(finalIntent.status, intent.status)
    }

    /// Verifies that `onCompletion` is called with an error after card reader finishes capturing payment, the card is removed successfully
    /// but the site fails to capture payment.
    ///
    func test_collectPayment_calls_onCompletion_with_failure_after_card_reader_capturePayment_success_but_site_capturePayment_failure() throws {
        // Given
        let intent = PaymentIntent.fake()
        // Success on client-side processing.
        mockCardReaderService.whenCapturingPayment(thenReturn: Just(intent)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher())
        // Success on card removal.
        mockCardReaderService.whenWaitForInsertedCardToBeRemoved(thenReturn: Future<Void, Never> { promise in
            promise(.success(()))
        })
        // Error on server-side processing.
        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment", filename: "generic_error")

        // When
        let result: Result<PaymentIntent, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction
                .collectPayment(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                parameters: .init(amount: 2.5, currency: "USD", stripeSmallestCurrencyUnitMultiplier: 100)) { cardReaderEvent in
                } onProcessingCompletion: { intent in
                } onCompletion: { result in
                    promise(result)
                }
            cardPresentStore.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? ServerSidePaymentCaptureError)
        guard case .paymentGateway = error else {
            return XCTFail("Unexpected payment gateway error: \(error)")
        }
    }

    /// Verifies that `CardReaderEvent.cardRemovedAfterPaymentCapture` is sent after card reader finishes capturing payment, the card is removed successfully
    /// and before the site captures payment.
    ///
    func test_collectPayment_sends_cardRemovedAfterPaymentCapture_event_after_card_removal_and_before_site_capturePayment_completion() {
        // Given
        let intent = PaymentIntent.fake()
        // Success on client-side processing.
        mockCardReaderService.whenCapturingPayment(thenReturn: Just(intent)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher())
        // Success on card removal.
        mockCardReaderService.whenWaitForInsertedCardToBeRemoved(thenReturn: Future<Void, Never> { promise in
            promise(.success(()))
        })
        // No mock response on the network call to `payments/orders/\(sampleOrderID)/capture_terminal_payment`.

        // When
        var cardReaderEvents: [CardReaderEvent] = []
        let _: Void = waitFor { promise in
            let action = CardPresentPaymentAction
                .collectPayment(siteID: self.sampleSiteID,
                                orderID: self.sampleOrderID,
                                parameters: .init(amount: 2.5, currency: "USD", stripeSmallestCurrencyUnitMultiplier: 100)) { cardReaderEvent in
                    cardReaderEvents.append(cardReaderEvent)
                    if cardReaderEvent == .cardRemovedAfterClientSidePaymentCapture {
                        promise(())
                    }
                } onProcessingCompletion: { intent in
                } onCompletion: { result in
                }
            self.cardPresentStore.onAction(action)
        }

        // Then
        // Only `cardRemovedAfterPaymentCapture` is sent from `CardPresentPaymentStore` while other events in production
        // are sent from `StripeCardReaderService` which is mocked here.
        XCTAssertEqual(cardReaderEvents, [.cardRemovedAfterClientSidePaymentCapture])
    }

    /// Verifies that after card reader finishes capturing payment with an error, `onCompletion` is called with a failure result
    /// and `onProcessingCompletion` is not called. Card removal is not necessary since the previous step already fails.
    ///
    func test_collectPayment_calls_onCompletion_but_not_onProcessingCompletion_after_card_reader_capturePayment_failure() throws {
        // Given
        let error = UnderlyingError.readerBusy
        mockCardReaderService.whenCapturingPayment(thenReturn: Fail<PaymentIntent, Error>(error: error)
            .eraseToAnyPublisher())
        mockCardReaderService.whenWaitForInsertedCardToBeRemoved(thenReturn: Future<Void, Never> { promise in
            // Card is not removed.
        })

        // When
        let result: Result<PaymentIntent, Error> = waitFor { [self] promise in
            let action = CardPresentPaymentAction
                .collectPayment(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                parameters: .init(amount: 2.5, currency: "USD", stripeSmallestCurrencyUnitMultiplier: 100)) { cardReaderEvent in
                } onProcessingCompletion: { intent in
                    XCTFail("`onProcessingCompletion` should only be called when payment capture succeeds.")
                } onCompletion: { result in
                    promise(result)
                }
            cardPresentStore.onAction(action)
        }

        // Then
        let errorFromResult = try XCTUnwrap(result.failure)
        XCTAssertEqual(errorFromResult as? UnderlyingError, error)
    }

    func test_selectedPaymentGatewayAccount_when_sent_use_before_then_returns_the_same_account() {
        // Given
        let account = PaymentGatewayAccount.fake()
        cardPresentStore.onAction(CardPresentPaymentAction.use(paymentGatewayAccount: account))

        let result = waitFor { promise in
            self.cardPresentStore.onAction(CardPresentPaymentAction.selectedPaymentGatewayAccount(onCompletion: { selectedAccount in
                promise(selectedAccount)
            }))
        }

        // Then
        XCTAssertEqual(result, account)
    }

    func test_checkDeviceSupport_action_passes_configuration_provider_to_service() {
        let action = CardPresentPaymentAction.checkDeviceSupport(siteID: sampleSiteID,
                                                                 cardReaderType: .appleBuiltIn,
                                                                 discoveryMethod: .localMobile,
                                                                 minimumOperatingSystemVersionOverride: nil,
                                                                 onCompletion: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertNotNil(mockCardReaderService.spyCheckSupportConfigProvider)
    }

    func test_checkDeviceSupport_action_passes_reader_type_and_discovery_method_to_service() {
        let action = CardPresentPaymentAction.checkDeviceSupport(siteID: sampleSiteID,
                                                                 cardReaderType: .chipper,
                                                                 discoveryMethod: .bluetoothScan,
                                                                 minimumOperatingSystemVersionOverride: nil,
                                                                 onCompletion: { _ in })

        cardPresentStore.onAction(action)

        assertEqual(.bluetoothScan, mockCardReaderService.spyCheckSupportDiscoveryMethod)
        assertEqual(.chipper, mockCardReaderService.spyCheckSupportCardReaderType)
    }

    func test_checkDeviceSupport_action_passes_operating_system_override_version_to_service() {
        let expectedVersion = OperatingSystemVersion(majorVersion: 16, minorVersion: 4, patchVersion: 0)
        let action = CardPresentPaymentAction.checkDeviceSupport(
            siteID: sampleSiteID,
            cardReaderType: .appleBuiltIn,
            discoveryMethod: .localMobile,
            minimumOperatingSystemVersionOverride: expectedVersion,
            onCompletion: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertNotNil(mockCardReaderService.spyCheckSupportMinimumOperatingSystemVersionOverride)
    }
}
