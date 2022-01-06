import XCTest
@testable import Networking


/// Stripe Remote Unit Tests
///
final class StripeRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that loadAccount properly handles the nominal response. We'll also validate the
    /// statement descriptor, currencies and country here.
    ///
    func test_loadAccount_properly_returns_account() throws {
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-complete")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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

    /// Verifies that loadAccount properly handles the rejected - fraud response
    ///
    func test_loadAccount_properly_handles_rejected_fraud_account() throws {
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-fraud")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-terms-of-service")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-listed")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-rejected-other")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-restricted")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-restricted-pending")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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

    /// Verifies that loadAccount properly handles the restricted - overdue response
    ///
    func test_loadAccount_properly_handles_restricted_overdue_account() throws {
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-restricted-overdue")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-unknown-status")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-wrong-json")

        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
        let error = result.failure
        XCTAssertTrue(error is DecodingError)
    }

    /// Properly decodes live account in live mode stripe-account-live-live
    ///
    func test_loadAccount_properly_handles_live_account_in_live_mode() throws {
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-live-live")

        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, true)
        XCTAssertEqual(account.isInTestMode, false)
    }

    /// Properly decodes live account in test mode stripe-account-live-test
    ///
    func test_loadAccount_properly_handles_live_account_in_test_mode() throws {
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-live-test")

        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.isLiveAccount, true)
        XCTAssertEqual(account.isInTestMode, true)
    }

    /// Properly decodes developer account in test mode stripe-account-dev-test
    ///
    func test_loadAccount_properly_handles_dev_account_in_test_mode() throws {
        let remote = StripeRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc_stripe/account/summary", filename: "stripe-account-dev-test")

        let result: Result<StripeAccount, Error> = waitFor { promise in
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
        let remote = StripeRemote(network: network)
        let expectedError = NSError(domain: #function, code: 0, userInfo: nil)

        network.simulateError(requestUrlSuffix: "wc_stripe/account/summary", error: expectedError)

        let result: Result<StripeAccount, Error> = waitFor { promise in
            remote.loadAccount(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure) as NSError
        XCTAssertEqual(expectedError, error)
    }
}
