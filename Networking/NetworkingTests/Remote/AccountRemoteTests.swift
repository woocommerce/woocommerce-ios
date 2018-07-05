import XCTest
@testable import Networking


/// AccountRemote Unit Tests
///
class AccountRemoteTests: XCTestCase {

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
        let remote = AccountRemote(network: network)
        let expectation = self.expectation(description: "Load Account Details")

        network.simulateResponse(requestUrlSuffix: "me", filename: "me")

        remote.loadAccount { (account, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(account)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
