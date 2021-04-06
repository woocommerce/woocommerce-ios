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
}
