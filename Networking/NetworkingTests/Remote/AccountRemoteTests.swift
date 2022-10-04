import Combine
import XCTest
@testable import Networking


/// AccountRemote Unit Tests
///
@MainActor
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
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")

        // When
        let result = waitFor { promise in
            remote.loadSites().sink { result in
                promise(result)
            }.store(in: &self.cancellables)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let sites = try XCTUnwrap(result.get())
        // Sites in `sites.json` include one Jetpack CP site and one site with Jetpack-the-plugin.
        let jcpSites = sites.filter { $0.isJetpackCPConnected }
        let nonJCPSites = sites.filter { $0.isJetpackCPConnected == false }
        XCTAssertEqual(jcpSites.count, 1)
        XCTAssertEqual(nonJCPSites.count, 1)
    }

    // MARK: - `checkIfWooCommerceIsActive`

    func test_checkIfWooCommerceIsActive_emits_true_when_response_is_valid() throws {
        // Given
        let siteID = Int64(277)
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings", filename: "wc-site-settings-partial")

        // When
        let result = waitFor { promise in
            remote.checkIfWooCommerceIsActive(for: siteID).sink { result in
                promise(result)
            }.store(in: &self.cancellables)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let isWooCommerceActive = try XCTUnwrap(result.get())
        XCTAssertTrue(isWooCommerceActive)
    }

    func test_checkIfWooCommerceIsActive_emits_false_when_error_is_returned() throws {
        // Given
        let siteID = Int64(277)
        let remote = AccountRemote(network: network)
        network.simulateError(requestUrlSuffix: "settings", error: NetworkError.notFound)

        // When
        let result = waitFor { promise in
            remote.checkIfWooCommerceIsActive(for: siteID).sink { result in
                promise(result)
            }.store(in: &self.cancellables)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(error, .notFound)
    }

    // MARK: - `fetchWordPressSiteSettings`

    func test_fetchWordPressSiteSettings_emits_settings_in_response() throws {
        // Given
        let siteID = Int64(277)
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(siteID)/settings", filename: "wp-site-settings")

        // When
        let result = waitFor { promise in
            remote.fetchWordPressSiteSettings(for: siteID).sink { result in
                promise(result)
            }.store(in: &self.cancellables)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteSettings = try XCTUnwrap(result.get())
        XCTAssertEqual(siteSettings.name, "Zucchini recipes")
    }

    // MARK: - `updateSettings`

    func test_updateSettings_displayName_returns_success_when_response_is_valid() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "update-account-display-name")

        // When
        let result = await remote.updateSettings(field: .displayName(value: "woo"))

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_updateSettings_password_returns_success_when_response_is_valid() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "update-account-password")

        // When
        let result = await remote.updateSettings(field: .password(value: "168"))

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_updateSettings_password_returns_DotcomError_on_error() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "update-account-password-error")

        // When
        let result = await remote.updateSettings(field: .password(value: "168"))

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unknown(code: "invalid_input", message: """
        This password is too easy to guess: you can improve it by adding additional uppercase letters, lowercase letters, or numbers.
        """))
    }

    // MARK: - `updateUsername`

    func test_updateUsername_returns_success_when_response_is_valid() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/username", filename: "update-account-username")

        // When
        let result = await remote.updateUsername(to: "woo seller")

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_updateUsername_returns_DotcomError_on_error() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/username", filename: "update-account-username-error")

        // When
        let result = await remote.updateUsername(to: "woo seller")

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unknown(code: "invalid_input",
                                       message: "Sorry, that username already exists!"))
    }

    // MARK: - `loadUsernameSuggestions`

    func test_loadUsernameSuggestions_returns_success_when_response_is_valid() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "username/suggestions", filename: "update-account-username-suggestions")

        // When
        let suggestions = await remote.loadUsernameSuggestions(from: "woo")

        // Then
        XCTAssertEqual(suggestions, ["woowriter", "woowoowoo", "woodaily"])
    }

    func test_loadUsernameSuggestions_returns_empty_suggestions_on_empty_response() async throws {
        // Given
        let remote = AccountRemote(network: network)

        // When
        let suggestions = await remote.loadUsernameSuggestions(from: "woo")

        // Then
        XCTAssertEqual(suggestions, [])
    }
}
