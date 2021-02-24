import XCTest
@testable import Networking


/// AccountSettingsRemote Unit Tests
///
class AccountSettingsRemoteTests: XCTestCase {

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
        let expectation = self.expectation(description: "Load Account Settings Details")

        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")

        remote.loadAccountSettings(for: 1) { (accountSettings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(accountSettings)
            XCTAssertEqual(1, accountSettings!.userID)
            XCTAssertTrue(accountSettings!.tracksOptOut)
            XCTAssertEqual(accountSettings!.firstName, "Dem 123")
            XCTAssertEqual(accountSettings!.lastName, "Nines")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
