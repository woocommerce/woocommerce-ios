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
}
