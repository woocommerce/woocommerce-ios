import XCTest
@testable import Networking
@testable import NetworkingCore
import TestKit

final class JetpackConnectionRemoteTests: XCTestCase {

    private let siteURL = "http://test.com"

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    func test_retrieveJetpackPluginDetails_correctly_returns_parsed_plugin() throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "wp/v2/plugins/jetpack/jetpack"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "site-plugin-without-envelope")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.retrieveJetpackPluginDetails { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plugin = try XCTUnwrap(result.get())
        assertEqual(plugin.plugin, "jetpack/jetpack")
        assertEqual(plugin.status, .active)
        assertEqual(plugin.name, "Jetpack")
    }

    func test_retrieveJetpackPluginDetails_properly_relays_errors() {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "wp/v2/plugins/jetpack/jetpack"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.retrieveJetpackPluginDetails { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_installJetpackPlugin_correctly_returns_parsed_plugin() throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "wp/v2/plugins"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "site-plugin-without-envelope")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.installJetpackPlugin { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plugin = try XCTUnwrap(result.get())
        assertEqual(plugin.plugin, "jetpack/jetpack")
        assertEqual(plugin.status, .active)
        assertEqual(plugin.name, "Jetpack")
    }

    func test_installJetpackPlugin_properly_relays_errors() {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "wp/v2/plugins"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.installJetpackPlugin { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_activateJetpackPlugin_correctly_returns_parsed_plugin() throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "wp/v2/plugins/jetpack/jetpack"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "site-plugin-without-envelope")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.activateJetpackPlugin { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plugin = try XCTUnwrap(result.get())
        assertEqual(plugin.plugin, "jetpack/jetpack")
        assertEqual(plugin.status, .active)
        assertEqual(plugin.name, "Jetpack")
    }

    func test_activateJetpackPlugin_properly_relays_errors() {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "wp/v2/plugins/jetpack/jetpack"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.activateJetpackPlugin { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_fetchJetpackConnectionURL_correctly_returns_parsed_url() throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/url"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connection-url")

        // When
        let result: Result<URL, Error> = waitFor { promise in
            remote.fetchJetpackConnectionURL { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let url = try XCTUnwrap(result.get())
        let expectedURL = "https://jetpack.wordpress.com/jetpack.authorize/1/?response_type=code&client_id=2099457"
        assertEqual(url.absoluteString, expectedURL)
    }

    func test_fetchJetpackConnectionURL_properly_relays_errors() {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/url"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<URL, Error> = waitFor { promise in
            remote.fetchJetpackConnectionURL { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_fetchJetpackConnectionData_correctly_returns_parsed_user() throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/data"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connected-user")

        // When
        let result: Result<JetpackConnectionData, Error> = waitFor { promise in
            remote.fetchJetpackConnectionData { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let user = try XCTUnwrap(result.get().currentUser)
        XCTAssertTrue(user.isConnected)
        XCTAssertNotNil(user.wpcomUser)
    }

    func test_fetchJetpackConnectionData_properly_relays_errors() {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/data"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<JetpackConnectionData, Error> = waitFor { promise in
            remote.fetchJetpackConnectionData { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_registerSite_correctly_returns_blogID() async throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/register"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connection-registration")

        // When
        let blogID = try await remote.registerSite()

        // Then
        XCTAssertEqual(blogID, 1234567890)
    }

    func test_registerSite_properly_relays_errors() async {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/register"
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: expectedError)

        do {
            // When
            _ = try await remote.registerSite()
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    func test_registerSite_throws_invalidAuthorizationURL_error_for_malformed_URL() async {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/connection/register"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connection-registration-invalid")

        do {
            // When
            _ = try await remote.registerSite()
        } catch {
            // Then
            XCTAssertEqual(error as? JetpackConnectionError, .invalidAuthorizationURL)
        }
    }

    func test_provisionConnection_correctly_returns_provision_response() async throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/remote_provision"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connection-provision")

        // When
        let response = try await remote.provisionConnection()

        // Then
        XCTAssertEqual(response.userId, 123456789)
        XCTAssertEqual(response.scope, "administrator")
        XCTAssertEqual(response.secret, "secret_token_12345")
    }

    func test_provisionConnection_properly_relays_errors() async {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, siteID: 123, network: network)
        let urlSuffix = "/jetpack/v4/remote_provision"
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: expectedError)

        do {
            // When
            _ = try await remote.provisionConnection()
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

}
