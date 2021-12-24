import XCTest
import Fakes

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

    func test_synchronizeSystemPlugins_stores_systemPlugins_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SystemStatusAction.synchronizeSystemPlugins(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSystemPlugin.self), 6) // number of systemPlugins in json file
    }

    func test_synchronizeSystemPlugins_removes_stale_systemPlugins_correctly() {
        // Given
        let staleSystemPluginName = "Stale System Plugin"
        let staleSystemPlugin = SystemPlugin.fake().copy(siteID: sampleSiteID, name: staleSystemPluginName)
        let storedStaleSystemPlugin = viewStorage.insertNewObject(ofType: StorageSystemPlugin.self)
        storedStaleSystemPlugin.update(with: staleSystemPlugin)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSystemPlugin.self), 1)

        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = SystemStatusAction.synchronizeSystemPlugins(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageSystemPlugin.self), 6) // number of systemPlugins in json file
        XCTAssertNil(viewStorage.loadSystemPlugin(siteID: sampleSiteID, name: staleSystemPluginName))
    }

    func test_fetchSystemPlugins_return_systemPlugins_correctly() {
        // Given
        let systemPlugin1 = viewStorage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin1.name = "Plugin 1"
        systemPlugin1.siteID = sampleSiteID

        let systemPlugin3 = viewStorage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin3.name = "Plugin 3"
        systemPlugin3.siteID = sampleSiteID

        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let systemPluginResult: Yosemite.SystemPlugin? = waitFor { promise in
            let action = SystemStatusAction.fetchSystemPlugin(siteID: self.sampleSiteID,
                                                               systemPluginName: "Plugin 3") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(systemPluginResult?.name, "Plugin 3") // number of systemPlugins in storage
    }

    func test_fetchSystemStatusReport_returns_systemStatus_correctly() {
        // Given
        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")
        let store = SystemStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<SystemStatus, Error> = waitFor { promise in
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
