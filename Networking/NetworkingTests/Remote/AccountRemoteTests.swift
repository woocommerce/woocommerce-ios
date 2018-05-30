import XCTest
@testable import Networking


/// AccountRemote Unit Tests
///
class AccountRemoteTests: XCTestCase {

    /// Dummy Credentials
    ///
    let credentials = Credentials(authToken: "Dummy!")

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that loadAccountDetails properly parses the `me` sample response.
    ///
    func testLoadAccountDetailsProperlyReturnsParsedAccount() {
        let remote = AccountRemote(credentials: credentials, network: network)
        let expectation = self.expectation(description: "Load Account Details")

        network.simulateResponse(requestUrlSuffix: "me", filename: "me")

        remote.loadAccountDetails { (account, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(account)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
