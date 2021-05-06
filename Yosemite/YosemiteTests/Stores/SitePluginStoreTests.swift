import XCTest
import Fakes

@testable import Yosemite
@testable import Networking
@testable import Storage

class SitePluginStoreTests: XCTestCase {
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
        let stalePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, name: "Stale Plugin")
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
    }
}
