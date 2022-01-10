import XCTest
@testable import Networking


/// WCPayRemote Unit Tests
///
final class WCPayRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    private let sampleOrderID: Int64 = 1467

    /// Dummy Payment Intent ID
    ///
    private let samplePaymentIntentID: String = "pi_123456789012345678901234"

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    /// Verifies that loadConnectionToken properly parses the sample response.
    ///
    func test_loadConnectionToken_properly_returns_parsed_token() {
        let remote = WCPayRemote(network: network)
        let expectation = self.expectation(description: "Load card reader token from WCPay extension")

        let expectedToken = "a connection token"

        network.simulateResponse(requestUrlSuffix: "payments/connection_tokens", filename: "wcpay-connection-token")
        remote.loadConnectionToken(for: sampleSiteID) { result in
            if case let .success(token) = result {
                XCTAssertEqual(token.token, expectedToken)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadConnectionToken properly relays Networking Layer errors.
    ///
    func test_loadConnectionToken_properly_relays_networking_errors() {
        let remote = WCPayRemote(network: network)
        let expectation = self.expectation(description: "Load WCPay token contains errors")

        remote.loadConnectionToken(for: sampleSiteID) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAccount properly handles the nominal response. We'll also validate the
    /// statement descriptor, currencies and country here.
    ///
    func test_loadAccount_properly_returns_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-complete")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .complete)
        XCTAssertEqual(account.statementDescriptor, "MY.FANCY.US.STORE")
        XCTAssertEqual(account.defaultCurrency, "usd")
        XCTAssertEqual(account.supportedCurrencies, ["usd"])
        XCTAssertEqual(account.country, "US")
        XCTAssertEqual(account.isCardPresentEligible, true)
    }

    /// Verifies that loadAccount properly detects when an account is NOT eligible for card present payments
    ///
    func test_loadAccount_properly_handles_not_eligible_for_card_present_payments() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-not-eligible")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isCardPresentEligible, false)
    }

    /// Verifies that loadAccount properly detects when an account is implicitly NOT eligible for card present payments
    /// i.e. when the response does not include the `card_present_eligible` flag
    ///
    func test_loadAccount_properly_handles_implicitly_not_eligible_for_card_present_payments() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-implicitly-not-eligible")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isCardPresentEligible, false)
    }

    /// Verifies that loadAccount properly handles the no account response
    ///
    func test_loadAccount_properly_handles_no_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-none")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .noAccount)
    }

    /// Verifies that loadAccount properly handles the rejected - fraud response
    ///
    func test_loadAccount_properly_handles_rejected_fraud_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-fraud")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedFraud)
    }

    /// Verifies that loadAccount properly handles the rejected - terms of service response
    ///
    func test_loadAccount_properly_handles_rejected_terms_of_service_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-terms-of-service")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedTermsOfService)
    }

    /// Verifies that loadAccount properly handles the rejected - listed response
    ///
    func test_loadAccount_properly_handles_rejected_listed_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-listed")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedListed)
    }

    /// Verifies that loadAccount properly handles the rejected - other response
    ///
    func test_loadAccount_properly_handles_rejected_other_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-other")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedOther)
    }

    /// Verifies that loadAccount properly handles the restricted (review) response
    ///
    func test_loadAccount_properly_handles_restricted_review_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-restricted")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .restricted)
        XCTAssertFalse(account.hasPendingRequirements)
        XCTAssertFalse(account.hasOverdueRequirements)
    }

    /// Verifies that loadAccount properly handles the restricted - pending response
    ///
    func test_loadAccount_properly_handles_restricted_pending_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-restricted-pending")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .restricted)
        XCTAssertTrue(account.hasPendingRequirements)
        XCTAssertFalse(account.hasOverdueRequirements)
        XCTAssertEqual(account.currentDeadline, Date(timeIntervalSince1970: 1897351200))
    }

    /// Verifies that loadAccount properly handles the restricted - over due response
    ///
    func test_loadAccount_properly_handles_restricted_over_due_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-restricted-overdue")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .restricted)
        XCTAssertFalse(account.hasPendingRequirements)
        XCTAssertTrue(account.hasOverdueRequirements)
    }

    /// Verifies that loadAccount properly handles an unrecognized status response
    ///
    func test_loadAccount_properly_handles_unrecognized_status_account() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-unknown-status")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .unknown)
    }

    /// Verifies that loadAccount properly handles unexpected fields in the response (resulting in a Decoding Error)
    ///
    func test_loadAccount_properly_handles_unexpected_fields_in_response() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-wrong-json")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
        let error = result.failure
        XCTAssertTrue(error is DecodingError)
    }

    /// Properly decodes live account in live mode wcpay-account-live-live
    ///
    func test_loadAccount_properly_handles_live_account_in_live_mode() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-live-live")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, true)
        XCTAssertEqual(account.isInTestMode, false)
    }

    /// Properly decodes live account in test mode wcpay-account-live-test
    ///
    func test_loadAccount_properly_handles_live_account_in_test_mode() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-live-test")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, true)
        XCTAssertEqual(account.isInTestMode, true)
    }

    /// Properly decodes developer account in test mode wcpay-account-dev-test
    ///
    func test_loadAccount_properly_handles_dev_account_in_test_mode() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-dev-test")

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, false)
        XCTAssertEqual(account.isInTestMode, true)
    }

    /// Verifies that loadAccount properly handles networking errors
    ///
    func test_loadAccount_properly_handles_networking_errors() throws {
        let remote = WCPayRemote(network: network)
        let expectedError = NSError(domain: #function, code: 0, userInfo: nil)

        network.simulateError(requestUrlSuffix: "payments/accounts", error: expectedError)

        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure) as NSError
        XCTAssertEqual(expectedError, error)
    }


    /// Verifies that captureOrderPayment properly handles a payment intent requires payment method response
    ///
    func test_captureOrderPayment_properly_handles_requires_payment_method_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-requires-payment-method")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .requiresPaymentMethod)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles a payment intent requires confirmation response
    ///
    func test_captureOrderPayment_properly_handles_requires_confirmation_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-requires-confirmation")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .requiresConfirmation)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles a payment intent requires action response
    ///
    func test_captureOrderPayment_properly_handles_requires_action_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-requires-action")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .requiresAction)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles a payment intent processing response
    ///
    func test_captureOrderPayment_properly_handles_processing_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-processing")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .processing)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles a payment intent requires capture response
    ///
    func test_captureOrderPayment_properly_handles_requires_capture_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-requires-capture")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .requiresCapture)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles a payment intent canceled response
    ///
    func test_captureOrderPayment_properly_handles_canceled_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-canceled")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .canceled)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles a payment intent succeeded response
    ///
    func test_captureOrderPayment_properly_handles_succeeded_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-succeeded")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .succeeded)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles an unrecognized payment intent status response
    ///
    func test_captureOrderPayment_properly_handles_unrecognized_status_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-unknown-status")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let paymentIntent = try result.get()
        XCTAssertEqual(paymentIntent.status, .unknown)
        XCTAssertEqual(paymentIntent.id, self.samplePaymentIntentID)
    }

    /// Verifies that captureOrderPayment properly handles an error response
    ///
    func test_captureOrderPayment_properly_handles_error_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture_terminal_payment",
                                 filename: "wcpay-payment-intent-error")

        let result: Result<WCPayPaymentIntent, Error> = waitFor { promise in
            remote.captureOrderPayment(for: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       paymentIntentID: self.samplePaymentIntentID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that fetchOrderCustomer properly parses the nominal response
    ///
    func test_fetchOrderCustomer_properly_returns_customer() throws {
        let remote = WCPayRemote(network: network)
        let expectedCustomerID = "cus_0123456789abcd"

        network.simulateResponse(
            requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
            filename: "wcpay-customer"
        )

        let result: Result<WCPayCustomer, Error> = waitFor { promise in
            remote.fetchOrderCustomer(for: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let customer = try result.get()
        XCTAssertEqual(customer.id, expectedCustomerID)
    }

    /// Verifies that fetchOrderCustomer properly handles an error response (i.e. the order does not exist)
    ///
    func test_fetchOrderCustomer_properly_handles_error_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(
            requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
            filename: "wcpay-customer-error"
        )

        let result: Result<WCPayCustomer, Error> = waitFor { promise in
            remote.fetchOrderCustomer(for: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
    }

    func test_loadDefaultReaderLocation_properly_returns_location() throws {
        let remote = WCPayRemote(network: network)
        let expectedLocationID = "tml_0123456789abcd"

        network.simulateResponse(
            requestUrlSuffix: "payments/terminal/locations/store",
            filename: "wcpay-location"
        )

        let result: Result<RemoteReaderLocation, Error> = waitFor { promise in
            remote.loadDefaultReaderLocation(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let location = try result.get()
        XCTAssertEqual(location.locationID, expectedLocationID)
    }

    func test_loadDefaultReaderLocation_properly_handles_error_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(
            requestUrlSuffix: "payments/terminal/locations/store",
            filename: "wcpay-location-error"
        )

        let result: Result<WCPayCustomer, Error> = waitFor { promise in
            remote.fetchOrderCustomer(for: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
    }
}
