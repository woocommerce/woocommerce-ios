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
    func test_loadAccount_properly_returns_parsed_account() {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me", filename: "me")

        // When
        let result: Result<Account, Error> = waitFor { promise in
            remote.loadAccount { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_updateAccountSettings_properly_returns_parsed_account() {
        // Given
        let remoteID: Int64 = 1
        let optOut = false
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")

        // When
        let result: Result<AccountSettings, Error> = waitFor { promise in
            remote.updateAccountSettings(for: remoteID, tracksOptOut: optOut) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }
}
