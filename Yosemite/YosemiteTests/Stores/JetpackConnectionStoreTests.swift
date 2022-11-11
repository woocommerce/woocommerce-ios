import XCTest
@testable import Yosemite
@testable import Networking

final class JetpackConnectionStoreTests: XCTestCase {

    private let siteURL = "http://test.com"

    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        dispatcher = Dispatcher()
    }

    func test_retrieveJetpackPluginDetails_returns_correct_plugin() throws {
        // Given
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "site-plugin-without-envelope")
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            let action = JetpackConnectionAction.retrieveJetpackPluginDetails { result in
                promise(result)
            }
            store.onAction(action)
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
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            let action = JetpackConnectionAction.retrieveJetpackPluginDetails { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_installJetpackPlugin_completes_successfully_when_the_installation_succeeds() throws {
        // Given
        let urlSuffix = "/wp/v2/plugins"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "site-plugin-without-envelope")
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = JetpackConnectionAction.installJetpackPlugin { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_installJetpackPlugin_properly_relays_errors() {
        // Given
        let urlSuffix = "/wp/v2/plugins"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = JetpackConnectionAction.installJetpackPlugin { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_activateJetpackPlugin_completes_successfully_when_the_activation_succeeds() throws {
        // Given
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "site-plugin-without-envelope")
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = JetpackConnectionAction.activateJetpackPlugin { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_activateJetpackPlugin_properly_relays_errors() {
        // Given
        let urlSuffix = "/wp/v2/plugins/jetpack/jetpack"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = JetpackConnectionAction.activateJetpackPlugin { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_fetchJetpackConnectionURL_returns_correct_url() throws {
        // Given
        let urlSuffix = "/jetpack/v4/connection/url"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connection-url")
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<URL, Error> = waitFor { promise in
            let action = JetpackConnectionAction.fetchJetpackConnectionURL { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let url = try XCTUnwrap(result.get())
        let expectedURL = "https://jetpack.wordpress.com/jetpack.authorize/1/?response_type=code&client_id=2099457"
        assertEqual(url.absoluteString, expectedURL)
    }

    func test_fetchJetpackConnectionURL_properly_relays_errors() {
        // Given
        let urlSuffix = "/jetpack/v4/connection/url"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<URL, Error> = waitFor { promise in
            let action = JetpackConnectionAction.fetchJetpackConnectionURL { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_fetchJetpackUser_correctly_returns_parsed_user() throws {
        // Given
        let urlSuffix = "/jetpack/v4/connection/data"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connected-user")
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<JetpackUser, Error> = waitFor { promise in
            let action = JetpackConnectionAction.fetchJetpackUser { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let user = try XCTUnwrap(result.get())
        XCTAssertTrue(user.isConnected)
        XCTAssertNotNil(user.wpcomUser)
    }

    func test_fetchJetpackUser_properly_relays_errors() {
        // Given
        let siteURL = "http://test.com"
        let urlSuffix = "/jetpack/v4/connection/data"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)
        let store = JetpackConnectionStore(dispatcher: dispatcher)

        let setupAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        store.onAction(setupAction)

        // When
        let result: Result<JetpackUser, Error> = waitFor { promise in
            let action = JetpackConnectionAction.fetchJetpackUser { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }
}
