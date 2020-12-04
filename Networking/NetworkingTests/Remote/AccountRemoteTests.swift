import XCTest
@testable import Networking


/// AccountRemote Unit Tests
///
class AccountRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

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

    func testUpdateAccountDetailsProperlyReturnsParsedAccount() {
        let remoteID: Int64 = 1
        let optOut = false
        let remote = AccountRemote(network: network)
        let expectation = self.expectation(description: "Update Account Details")

        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")
        remote.updateAccountSettings(for: remoteID, tracksOptOut: optOut) { (accountSettings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(accountSettings)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
