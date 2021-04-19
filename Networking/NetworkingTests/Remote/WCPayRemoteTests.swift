import XCTest
@testable import Networking


/// WCPayRemote Unit Tests
///
final class WCPayRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID: Int64 = 1467

    /// Dummy Payment Intent ID
    ///
    let samplePaymentIntentID: String = "pi_123456789012345678901234"

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that loadConnectionToken properly parses the sample response.
    ///
    func test_loadConnectionToken_properly_returns_parsed_token() {
        let remote = WCPayRemote(network: network)
        let expectation = self.expectation(description: "Load WCPay token")

        let expectedToken = "a connection token"

        network.simulateResponse(requestUrlSuffix: "payments/connection_tokens", filename: "wcpay-connection-token")
        remote.loadConnectionToken(for: sampleSiteID) { (token, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            XCTAssertEqual(token?.token, expectedToken)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadConnectionToken properly relays Networking Layer errors.
    ///
    func test_loadConnectionToken_properly_relays_networking_errors() {
        let remote = WCPayRemote(network: network)
        let expectation = self.expectation(description: "Load WCPay token contains errors")

        remote.loadConnectionToken(for: sampleSiteID) { (token, error) in
            XCTAssertNil(token)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAccount properly handles the nominal response. We'll also validate the
    /// statement descriptor, currencies and country here.
    ///
    func test_loadAccount_properly_returns_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-complete")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .complete)
            XCTAssertEqual(account.statementDescriptor, "MY.FANCY.US.STORE")
            XCTAssertEqual(account.defaultCurrency, "usd")
            XCTAssertEqual(account.supportedCurrencies, ["usd"])
            XCTAssertEqual(account.country, "US")
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the no account response
    ///
    func test_loadAccount_properly_handles_no_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-none")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .noAccount)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the rejected - fraud response
    ///
    func test_loadAccount_properly_handles_rejected_fraud_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-fraud")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .rejectedFraud)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the rejected - terms of service response
    ///
    func test_loadAccount_properly_handles_rejected_terms_of_service_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-terms-of-service")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .rejectedTermsOfService)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the rejected - listed response
    ///
    func test_loadAccount_properly_handles_rejected_listed_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-listed")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .rejectedListed)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the rejected - other response
    ///
    func test_loadAccount_properly_handles_rejected_other_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-rejected-other")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .rejectedOther)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the restricted (review) response
    ///
    func test_loadAccount_properly_handles_restricted_review_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-restricted")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .restricted)
            XCTAssertFalse(account.hasPendingRequirements)
            XCTAssertFalse(account.hasOverdueRequirements)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the restricted - pending response
    ///
    func test_loadAccount_properly_handles_restricted_pending_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-restricted-pending")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .restricted)
            XCTAssertTrue(account.hasPendingRequirements)
            XCTAssertFalse(account.hasOverdueRequirements)
            XCTAssertEqual(account.currentDeadline, Date(timeIntervalSince1970: 1897351200))
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles the restricted - over due response
    ///
    func test_loadAccount_properly_handles_restricted_over_due_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-restricted-overdue")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .restricted)
            XCTAssertFalse(account.hasPendingRequirements)
            XCTAssertTrue(account.hasOverdueRequirements)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles an unrecognized status response
    ///
    func test_loadAccount_properly_handles_unrecognized_status_account() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-unknown-status")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertEqual(account.status, .unknown)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadAccount properly handles an error response
    ///
    func test_loadAccount_properly_handles_error_response() {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/accounts", filename: "wcpay-account-error")

        // When
        let result: Result<WCPayAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let account):
            XCTAssertNil(account)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    /// Verifies that captureOrderPayment properly handles a payment intent requires payment method response
    ///
    func test_captureOrderPayment_properly_handles_requires_payment_method_response() throws {
        let remote = WCPayRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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

        network.simulateResponse(requestUrlSuffix: "payments/orders/\(sampleOrderID)/capture",
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
}
