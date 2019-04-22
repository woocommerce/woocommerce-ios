import XCTest
@testable import Networking


/// AccountSettingsRemote Unit Tests
///
class AccountSettingsRemoteTests: XCTestCase {

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
        let expectation = self.expectation(description: "Load Account Settings Details")

        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")

        remote.loadAccountSettings { (accountSettings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(accountSettings)
            XCTAssertTrue(accountSettings!.tracksOptOut)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
