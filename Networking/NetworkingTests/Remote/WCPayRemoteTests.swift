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
}

