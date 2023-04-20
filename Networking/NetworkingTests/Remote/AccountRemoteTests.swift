import Combine
import XCTest
import TestKit
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
        let publicSites = sites.filter { $0.isPublic }
        XCTAssertEqual(jcpSites.count, 1)
        XCTAssertEqual(nonJCPSites.count, 1)
        XCTAssertEqual(publicSites.count, 1)
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

    // MARK: - `loadUsernameSuggestions`

    func test_loadUsernameSuggestions_returns_suggestions_on_success() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "username/suggestions", filename: "account-username-suggestions")

        // When
        let suggestions = try await remote.loadUsernameSuggestions(from: "woo")

        // Then
        XCTAssertEqual(suggestions, ["woowriter", "woowoowoo", "woodaily"])
    }

    func test_loadUsernameSuggestions_returns_empty_suggestions_on_empty_response() async throws {
        // Given
        let remote = AccountRemote(network: network)

        await assertThrowsError({  _ = try await remote.loadUsernameSuggestions(from: "woo")}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `createAccount`

    func test_createAccount_returns_auth_token_on_success() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "users/new", filename: "create-account-success")

        // When
        let result = await remote.createAccount(email: "coffee@woo.com", username: "", password: "", clientID: "", clientSecret: "")

        // Then
        let data = try XCTUnwrap(result.get())
        XCTAssertEqual(data.authToken, "🐻")
        XCTAssertEqual(data.username, "wootest")
    }

    func test_createAccount_returns_emailExists_error_on_email_exists_error() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "users/new", filename: "create-account-error-email-exists")

        // When
        let result = await remote.createAccount(email: "coffee@woo.com", username: "", password: "", clientID: "", clientSecret: "")

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .emailExists)
    }

    func test_createAccount_returns_invalidEmail_error_on_invalid_email_error() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "users/new", filename: "create-account-error-invalid-email")

        // When
        let result = await remote.createAccount(email: "coffee@woo.com", username: "", password: "", clientID: "", clientSecret: "")

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidEmail)
    }

    func test_createAccount_returns_password_error_on_invalid_password_error() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "users/new", filename: "create-account-error-password")

        // When
        let result = await remote.createAccount(email: "coffee@woo.com", username: "", password: "", clientID: "", clientSecret: "")

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidPassword(message:
                                                "Your password is too short. Please pick a password that has at least 6 characters."))
    }

    func test_createAccount_returns_invalidUsername_error_on_invalid_username_error() async throws {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "users/new", filename: "create-account-error-username")

        // When
        let result = await remote.createAccount(email: "coffee@woo.com", username: "", password: "", clientID: "", clientSecret: "")

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidUsername)
    }

    // MARK: - `closeAccount`

    func test_closeAccount_succeeds_on_request_success() async {
        // Given
        let remote = AccountRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/account/close", filename: "close-account")

        // When
        var errorCaught: Error?
        do {
            try await remote.closeAccount()
        } catch {
            errorCaught = error
        }

        // Then
        XCTAssertNil(errorCaught)
    }

    func test_closeAccount_relays_error_on_request_failure() async {
        // Given
        let remote = AccountRemote(network: network)
        let expectedError = NetworkError.timeout
        network.simulateError(requestUrlSuffix: "me/account/close", error: expectedError)

        // When
        var errorCaught: Error?
        do {
            try await remote.closeAccount()
        } catch {
            errorCaught = error
        }

        // Then
        XCTAssertEqual(expectedError, errorCaught as? NetworkError)
    }
}
