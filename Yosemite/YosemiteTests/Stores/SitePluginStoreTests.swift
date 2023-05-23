import XCTest
import Fakes

@testable import Yosemite
@testable import Networking
@testable import Storage

final class SitePluginStoreTests: XCTestCase {
    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    private var remote: MockSitePluginsRemote!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 12345

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockSitePluginsRemote()
    }

    override func tearDown() {
        super.tearDown()
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
    }

    func test_synchronizeSitePlugins_stores_plugins_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugins")
        let store = SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SitePluginAction.synchronizeSitePlugins(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSitePlugin.self), 5) // number of plugins in json file
    }

    func test_synchronizeSitePlugins_removes_stale_plugins_correctly() {
        // Given
        let stalePluginName = "Stale Plugin"
        let stalePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, name: stalePluginName)
        let storedStalePlugin = viewStorage.insertNewObject(ofType: StorageSitePlugin.self)
        storedStalePlugin.update(with: stalePlugin)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSitePlugin.self), 1)

        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugins")
        let store = SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SitePluginAction.synchronizeSitePlugins(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSitePlugin.self), 5) // number of plugins in json file
        XCTAssertNil(viewStorage.loadPlugin(siteID: sampleSiteID, name: stalePluginName))
    }

    func test_installSitePlugin_stores_plugin_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugin")
        let store = SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SitePluginAction.installSitePlugin(siteID: self.sampleSiteID, slug: "jetpack") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plugins = viewStorage.loadPlugins(siteID: sampleSiteID)
        XCTAssertEqual(plugins.count, 1) // the installed plugin
        XCTAssertEqual(plugins.first?.plugin, "jetpack/jetpack")
    }

    func test_activateSitePlugin_updates_plugin_correctly() {
        // Given
        let pluginName = "jetpack/jetpack"
        let plugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: pluginName)
        let storedPlugin = viewStorage.insertNewObject(ofType: StorageSitePlugin.self)
        storedPlugin.update(with: plugin)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSitePlugin.self), 1)

        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin")
        let store = SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SitePluginAction.activateSitePlugin(siteID: self.sampleSiteID, pluginName: pluginName) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plugins = viewStorage.loadPlugins(siteID: sampleSiteID)
        XCTAssertEqual(plugins.count, 1) // the installed plugin
        XCTAssertEqual(plugins.first?.status, SitePluginStatusEnum.active.rawValue)
    }

    func test_activateSitePlugin_completes_with_failure_when_receiving_inactive_plugin() {
        // Given
        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin-inactive")
        let store = SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SitePluginAction.activateSitePlugin(siteID: self.sampleSiteID, pluginName: "jetpack/jetpack") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_getPluginDetails_stores_plugin_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "plugins/jetpack/jetpack", filename: "plugin")
        let store = SitePluginStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let pluginName = "jetpack/jetpack"

        // When
        let result: Result<Networking.SitePlugin, Error> = waitFor { promise in
            let action = SitePluginAction.getPluginDetails(siteID: self.sampleSiteID, pluginName: pluginName) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plugins = viewStorage.loadPlugins(siteID: sampleSiteID)
        XCTAssertEqual(plugins.count, 1) // the installed plugin
        XCTAssertEqual(plugins.first?.plugin, "jetpack/jetpack")
    }

    // MARK: - `isPluginActive`

    func test_arePluginsActive_for_jetpack_woo_returns_true_when_site_has_both_plugins() throws {
        // Given
        remote.whenLoadingPluginsFromWPCOM(thenReturn: .success([.init(id: "jetpack/jetpack", isActive: true),
                                                                 .init(id: "woocommerce/woocommerce", isActive: true)]))
        let store = SitePluginStore(remote: remote, dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result = waitFor { promise in
            store.onAction(SitePluginAction.arePluginsActive(siteID: 122, plugins: [.jetpack, .woo]) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let arePluginsActive = try XCTUnwrap(result.get())
        XCTAssertTrue(arePluginsActive)
    }

    func test_arePluginsActive_for_jetpack_woo_returns_false_when_site_does_not_have_both_plugins() throws {
        // Given
        remote.whenLoadingPluginsFromWPCOM(thenReturn: .success([.init(id: "automatewoo/automatewoo", isActive: true)]))
        let store = SitePluginStore(remote: remote, dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result = waitFor { promise in
            store.onAction(SitePluginAction.arePluginsActive(siteID: 122, plugins: [.jetpack, .woo]) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let arePluginsActive = try XCTUnwrap(result.get())
        XCTAssertFalse(arePluginsActive)
    }

    func test_arePluginsActive_for_jetpack_woo_returns_false_when_site_only_has_one_plugin() throws {
        // Given
        remote.whenLoadingPluginsFromWPCOM(thenReturn: .success([.init(id: "jetpack/jetpack", isActive: true)]))
        let store = SitePluginStore(remote: remote, dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result = waitFor { promise in
            store.onAction(SitePluginAction.arePluginsActive(siteID: 122, plugins: [.jetpack, .woo]) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let arePluginsActive = try XCTUnwrap(result.get())
        XCTAssertFalse(arePluginsActive)
    }

    func test_arePluginsActive_for_jetpack_returns_error_when_loadPluginsFromWPCOM_fails() throws {
        // Given
        remote.whenLoadingPluginsFromWPCOM(thenReturn: .failure(NetworkError.invalidURL))
        let store = SitePluginStore(remote: remote, dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result = waitFor { promise in
            store.onAction(SitePluginAction.arePluginsActive(siteID: 122, plugins: [.jetpack, .woo]) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .invalidURL)
    }
}
