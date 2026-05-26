import XCTest
import Fakes

import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking
@testable import Storage

final class SystemStatusStoreTests: XCTestCase {
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
    private let sampleSiteID: Int64 = 99999

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    func test_synchronizeSystemInformation_stores_systemPlugins_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result = waitFor { promise in
            store.onAction(SystemStatusAction.synchronizeSystemInformation(siteID: self.sampleSiteID) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSystemPlugin.self), 6) // number of systemPlugins in json file
    }

    func test_synchronizeSystemInformation_stores_storeID_correctly() throws {
        // Given
        let mockProcessor = MockActionsProcessor()
        dispatcher.register(processor: mockProcessor, for: AppSettingsAction.self)

        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        _ = waitFor { promise in
            store.onAction(SystemStatusAction.synchronizeSystemInformation(siteID: self.sampleSiteID) { result in
                promise(result)
            })
        }

        // Then
        let action = try XCTUnwrap(mockProcessor.receivedActions.first as? AppSettingsAction)
        switch action {
        case AppSettingsAction.setStoreID(_, let id):
            XCTAssertEqual(id, "sample-store-uuid") // store id in json file
        default:
            XCTFail("Unexpected action: \(mockProcessor.receivedActions), expecting AppSettingsAction.setStoreID")
        }
    }

    func test_synchronizeSystemInformation_removes_stale_systemPlugins_correctly() {
        // Given
        let staleSystemPluginPath = "folder/stale-plugin.php"
        let staleSystemPlugin = SystemPlugin.fake().copy(siteID: sampleSiteID, plugin: staleSystemPluginPath)
        let storedStaleSystemPlugin = viewStorage.insertNewObject(ofType: StorageSystemPlugin.self)
        storedStaleSystemPlugin.update(with: staleSystemPlugin)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSystemPlugin.self), 1)

        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result = waitFor { promise in
            store.onAction(SystemStatusAction.synchronizeSystemInformation(siteID: self.sampleSiteID) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSystemPlugin.self), 6) // number of systemPlugins in json file
        XCTAssertNil(viewStorage.loadSystemPlugin(siteID: sampleSiteID, fileNameWithoutExtension: "stale-plugin"))
    }

    func test_fetchSystemPluginWithPath_returns_plugin_when_matching_plugin_is_in_storage() {
        // Given
        let systemPlugin1 = viewStorage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin1.name = "WooPayments"
        systemPlugin1.plugin = "woocommerce-payments/woocommerce-payments.php"
        systemPlugin1.siteID = sampleSiteID

        let systemPlugin2 = viewStorage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin2.name = "Gift Cards"
        systemPlugin2.plugin = "woocommerce-gift-cards/woocommerce-gift-cards.php"
        systemPlugin2.siteID = sampleSiteID

        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let fetchedPlugin = waitFor { promise in
            store.onAction(SystemStatusAction.fetchSystemPluginWithPath(siteID: self.sampleSiteID,
                                                                      pluginPath: "woocommerce-gift-cards/woocommerce-gift-cards.php") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertEqual(fetchedPlugin?.name, "Gift Cards")
        XCTAssertEqual(fetchedPlugin?.plugin, "woocommerce-gift-cards/woocommerce-gift-cards.php")
    }

    func test_fetchSystemPluginWithPath_returns_nil_when_no_matching_plugin() {
        // Given
        let systemPlugin = viewStorage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin.name = "WooPayments"
        systemPlugin.plugin = "woocommerce-payments/woocommerce-payments.php"
        systemPlugin.siteID = sampleSiteID

        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let fetchedPlugin = waitFor { promise in
            store.onAction(SystemStatusAction.fetchSystemPluginWithPath(siteID: self.sampleSiteID,
                                                                      pluginPath: "woocommerce-gift-cards/woocommerce-gift-cards.php") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertNil(fetchedPlugin)
    }

    func test_fetchSystemStatusReport_returns_systemStatus_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<SystemStatusReport, Error> = waitFor { promise in
            let action = SystemStatusAction.fetchSystemStatusReport(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual((try? result.get())?.environment?.siteURL, "https://additional-beetle.jurassic.ninja") // site URL of the site in the json file
    }
}
