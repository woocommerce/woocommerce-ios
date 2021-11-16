import Combine
import XCTest
@testable import Networking


/// AccountRemote Unit Tests
///
final class AccountRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    private var cancellables = Set<AnyCancellable>()

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
        cancellables = []
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

    // MARK: - `loadSites`

    func test_loadSites_emits_sites_in_response() throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "me-sites-one-jcp-site")

        // When
        let result = waitFor { promise in
            remote.loadSites().sink { result in
                promise(result)
            }.store(in: &self.cancellables)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let sites = try XCTUnwrap(result.get())
        let jcpSites = sites.filter { $0.isJetpackCPConnected }
        let nonJCPSites = sites.filter { $0.isJetpackCPConnected == false }
        XCTAssertEqual(jcpSites.count, 1)
        XCTAssertEqual(nonJCPSites.count, 1)
    }
}
