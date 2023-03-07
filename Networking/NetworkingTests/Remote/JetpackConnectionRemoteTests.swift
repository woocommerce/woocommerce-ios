import XCTest
@testable import Networking

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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/wp/v2/plugins"
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/wp/v2/plugins"
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
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
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
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

    func test_fetchJetpackUser_correctly_returns_parsed_user() throws {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/jetpack/v4/connection/data"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connected-user")

        // When
        let result: Result<JetpackUser, Error> = waitFor { promise in
            remote.fetchJetpackUser { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let user = try XCTUnwrap(result.get())
        XCTAssertTrue(user.isConnected)
        XCTAssertNotNil(user.wpcomUser)
    }

    func test_fetchJetpackUser_properly_relays_errors() {
        // Given
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/jetpack/v4/connection/data"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<JetpackUser, Error> = waitFor { promise in
            remote.fetchJetpackUser { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }
}
