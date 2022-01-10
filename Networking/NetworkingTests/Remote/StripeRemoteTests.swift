import XCTest
@testable import Networking


/// Stripe Remote Unit Tests
///
final class StripeRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    private let sampleOrderID: Int64 = 1467

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
        let expectation = self.expectation(description: "Load card reader token from Stripe extension")

        let expectedToken = "a connection token"

        network.simulateResponse(requestUrlSuffix: "payments/connection_tokens", filename: "stripe-connection-token")
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
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-complete")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .complete)
        XCTAssertEqual(account.statementDescriptor, "MY.FANCY.US.STORE")
        XCTAssertEqual(account.defaultCurrency, "usd")
        XCTAssertEqual(account.supportedCurrencies, ["usd"])
        XCTAssertEqual(account.country, "US")
        XCTAssertEqual(account.isCardPresentEligible, true)
    }

    /// Verifies that loadAccount properly handles the rejected - fraud response
    ///
    func test_loadAccount_properly_handles_rejected_fraud_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-fraud")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedFraud)
    }

    /// Verifies that loadAccount properly handles the rejected - terms of service response
    ///
    func test_loadAccount_properly_handles_rejected_terms_of_service_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-terms-of-service")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedTermsOfService)
    }

    /// Verifies that loadAccount properly handles the rejected - listed response
    ///
    func test_loadAccount_properly_handles_rejected_listed_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-listed")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedListed)
    }

    /// Verifies that loadAccount properly handles the rejected - other response
    ///
    func test_loadAccount_properly_handles_rejected_other_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-other")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .rejectedOther)
    }

    /// Verifies that loadAccount properly handles the restricted (review) response
    ///
    func test_loadAccount_properly_handles_restricted_review_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-restricted")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .restricted)
        XCTAssertFalse(account.hasPendingRequirements)
        XCTAssertFalse(account.hasOverdueRequirements)
    }

    /// Verifies that loadAccount properly handles the restricted - pending response
    ///
    func test_loadAccount_properly_handles_restricted_pending_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-restricted-pending")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .restricted)
        XCTAssertTrue(account.hasPendingRequirements)
        XCTAssertFalse(account.hasOverdueRequirements)
        XCTAssertEqual(account.currentDeadline, Date(timeIntervalSince1970: 1897351200))
    }

    /// Verifies that loadAccount properly handles the restricted - overdue response
    ///
    func test_loadAccount_properly_handles_restricted_overdue_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-restricted-overdue")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .restricted)
        XCTAssertFalse(account.hasPendingRequirements)
        XCTAssertTrue(account.hasOverdueRequirements)
    }

    /// Verifies that loadAccount properly handles an unrecognized status response
    ///
    func test_loadAccount_properly_handles_unrecognized_status_account() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-unknown-status")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.status, .unknown)
    }

    /// Verifies that loadAccount properly handles unexpected fields in the response (resulting in a Decoding Error)
    ///
    func test_loadAccount_properly_handles_unexpected_fields_in_response() {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-wrong-json")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = result.failure
        XCTAssertTrue(error is DecodingError)
    }

    /// Properly decodes live account in live mode stripe-account-live-live
    ///
    func test_loadAccount_properly_handles_live_account_in_live_mode() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-live-live")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, true)
        XCTAssertEqual(account.isInTestMode, false)
    }

    /// Properly decodes live account in test mode stripe-account-live-test
    ///
    func test_loadAccount_properly_handles_live_account_in_test_mode() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-live-test")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, true)
        XCTAssertEqual(account.isInTestMode, true)
    }

    /// Properly decodes developer account in test mode stripe-account-dev-test
    ///
    func test_loadAccount_properly_handles_dev_account_in_test_mode() throws {
        // Given
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-dev-test")

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, false)
        XCTAssertEqual(account.isInTestMode, true)
    }

    /// Verifies that loadAccount properly handles networking errors
    ///
    func test_loadAccount_properly_handles_networking_errors() throws {
        // Given
        let remote = StripeRemote(network: network)
        let expectedError = NSError(domain: #function, code: 0, userInfo: nil)

        network.simulateError(requestUrlSuffix: "wc_stripe/account/summary", error: expectedError)

        // When
        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure) as NSError
        XCTAssertEqual(expectedError, error)
    }

    /// Verifies that fetchOrderCustomer properly parses the nominal response
    ///
    func test_fetchOrderCustomer_properly_returns_customer() throws {
        let remote = StripeRemote(network: network)
        let expectedCustomerID = "cus_0123456789abcd"

        network.simulateResponse(
            requestUrlSuffix: "payments/orders/\(sampleOrderID)/create_customer",
            filename: "wcpay-customer"
        )

        let result: Result<Customer, Error> = waitFor { promise in
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
            filename: "stripe-customer-error"
        )

        let result: Result<Customer, Error> = waitFor { promise in
            remote.fetchOrderCustomer(for: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
    }
}
