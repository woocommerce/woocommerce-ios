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
    func test_loadAccountSettings_properly_returns_parsed_account() throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")

        // When
        let result: Result<AccountSettings, Error> = waitFor { promise in
            remote.loadAccountSettings(for: 1) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let accountSettings = try result.get()
        XCTAssertTrue(accountSettings.tracksOptOut)
        XCTAssertEqual(accountSettings.userID, 1)
        XCTAssertEqual(accountSettings.firstName, "Dem 123")
        XCTAssertEqual(accountSettings.lastName, "Nines")
    }
}
