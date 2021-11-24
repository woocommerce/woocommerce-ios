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
    func test_loadPlugins_properly_returns_plugins() {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugins")

        // When
        let result: Result<[SitePlugin], Error> = waitFor { promise in
            remote.loadPlugins(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let plugins):
            XCTAssertEqual(plugins.count, 5)
        case .failure(let error):
            XCTAssertNil(error)
        }
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
        switch result {
        case .success(let plugins):
            XCTAssertNil(plugins)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Install plugin tests

    /// Verifies that installPlugin properly parses the sample response.
    ///
    func test_installPlugin_properly_returns_plugins() {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugin")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.installPlugin(for: self.sampleSiteID, slug: "jetpack") { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let plugin):
            XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
        case .failure(let error):
            XCTAssertNil(error)
        }
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
        switch result {
        case .success(let plugin):
            XCTAssertNil(plugin)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Activate plugin tests

    /// Verifies that activatePlugin properly parses the sample response.
    ///
    func test_activatePlugin_properly_returns_plugins() {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.activatePlugin(for: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let plugin):
            XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
        case .failure(let error):
            XCTAssertNil(error)
        }
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
        switch result {
        case .success(let plugin):
            XCTAssertNil(plugin)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Get plugin details tests

    /// Verifies that getPluginDetails properly parses the sample response.
    ///
    func test_getPluginDetails_properly_returns_plugins() {
        let remote = SitePluginsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin")

        // When
        let result: Result<SitePlugin, Error> = waitFor { promise in
            remote.getPluginDetails(for: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let plugin):
            XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
        case .failure(let error):
            XCTAssertNil(error)
        }
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
        switch result {
        case .success(let plugin):
            XCTAssertNil(plugin)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
}
