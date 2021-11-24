import XCTest
@testable import Networking

/// SitePluginsRemote Unit Tests
///
class SitePluginsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load plugins tests

    /// Verifies that loadPlugins properly parses the sample response.
    ///
    func test_loadPlugins_properly_returns_plugins() throws {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugins")

        // When
        let result: Result<[SitePlugin], Error> = waitFor { promise in
            remote.loadPlugins(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let plugins = try XCTUnwrap(result.get())
        XCTAssertEqual(plugins.count, 5)
    }

    /// Verifies that loadPlugins properly relays Networking Layer errors.
    ///
    func test_loadPlugins_properly_relays_netwoking_errors() {
        let remote = SitePluginsRemote(network: network)

        // When
        let result: Result<[SitePlugin], Error> = waitFor { promise in
            remote.loadPlugins(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Install plugin tests

    /// Verifies that installPlugin properly parses the sample response.
    ///
    func test_installPlugin_properly_returns_plugin() throws {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugin")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.installPlugin(for: self.sampleSiteID, slug: "jetpack") { result in
                promise(result)
            }
        }

        // Then
        let plugin = try XCTUnwrap(result.get())
        XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
    }

    /// Verifies that installPlugin properly relays Networking Layer errors.
    ///
    func test_installPlugin_properly_relays_netwoking_errors() {
        let remote = SitePluginsRemote(network: network)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.installPlugin(for: self.sampleSiteID, slug: "jetpack") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Activate plugin tests

    /// Verifies that activatePlugin properly parses the sample response.
    ///
    func test_activatePlugin_properly_returns_plugins() throws {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.activatePlugin(for: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
        }

        // Then
        let plugin = try XCTUnwrap(result.get())
        XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
    }

    /// Verifies that activatePlugin properly relays Networking Layer errors.
    ///
    func test_activatePlugin_properly_relays_netwoking_errors() {
        let remote = SitePluginsRemote(network: network)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.activatePlugin(for: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Get plugin details tests

    /// Verifies that getPluginDetails properly parses the sample response.
    ///
    func test_getPluginDetails_properly_returns_plugins() throws {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.getPluginDetails(for: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
        }

        // Then
        let plugin = try XCTUnwrap(result.get())
        XCTAssertEqual(plugin.status, .active)
    }

    /// Verifies that getPluginDetails properly relays Networking Layer errors.
    ///
    func test_getPluginDetails_properly_relays_netwoking_errors() {
        let remote = SitePluginsRemote(network: network)

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.getPluginDetails(for: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
