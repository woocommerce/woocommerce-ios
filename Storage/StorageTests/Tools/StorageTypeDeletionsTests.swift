import XCTest
@testable import Storage

class StorageTypeDeletionsTests: XCTestCase {

    private let sampleSiteID: Int64 = 98765
    private var storageManager: StorageManagerType!

    private var storage: StorageType! {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func test_deleteStaleAddOnGroups_does_not_delete_active_addOns() throws {
        // Given
        let initialGroups: [AddOnGroup] = [
            createAddOnGroup(groupID: 123, name: "AAA"),
            createAddOnGroup(groupID: 1234, name: "BBB"),
            createAddOnGroup(groupID: 12345, name: "CCC")
        ]

        // When
        storage.deleteStaleAddOnGroups(siteID: sampleSiteID, activeGroupIDs: [123, 1234])

        // Then
        let activeGroups = storage.loadAddOnGroups(siteID: sampleSiteID)
        XCTAssertEqual(activeGroups, initialGroups.dropLast())
    }

    func test_deleteStalePlugins_deletes_plugins_not_included_in_installedPluginNames() throws {
        // Given
        let plugin1 = createPlugin(name: "AAA")
        _ = createPlugin(name: "BBB")
        let plugin3 = createPlugin(name: "CCC")

        // When
        storage.deleteStalePlugins(siteID: sampleSiteID, installedPluginNames: ["AAA", "CCC"])

        // Then
        let currentPlugins = storage.loadPlugins(siteID: sampleSiteID)
        XCTAssertEqual(currentPlugins, [plugin1, plugin3])
    }

    // MARK: - System plugins

    func test_deleteStaleSystemPlugins_deletes_systemPlugins_not_included_in_currentSystemPlugins() throws {
        // Given
        _ = createSystemPlugin(name: "Plugin 1")
        _ = createSystemPlugin(name: "Plugin 2")
        let systemPlugin3 = createSystemPlugin(name: "Plugin 3")

        // When
        storage.deleteStaleSystemPlugins(siteID: sampleSiteID, currentSystemPlugins: ["Plugin 3"])

        // Then
        let currrentSystemPlugin = storage.loadSystemPlugins(siteID: sampleSiteID)
        XCTAssertEqual(currrentSystemPlugin, [systemPlugin3])
    }
}

private extension StorageTypeDeletionsTests {
    /// Inserts and creates an `AddOnGroup` ready to be used on tests.
    ///
    func createAddOnGroup(groupID: Int64, name: String) -> AddOnGroup {
        let addOnGroup = storage.insertNewObject(ofType: AddOnGroup.self)
        addOnGroup.siteID = sampleSiteID
        addOnGroup.groupID = groupID
        addOnGroup.name = name
        return addOnGroup
    }

    /// Creates and inserts a `SitePlugin` entity with a given name
    ///
    func createPlugin(name: String) -> SitePlugin {
        let plugin = storage.insertNewObject(ofType: SitePlugin.self)
        plugin.siteID = sampleSiteID
        plugin.name = name
        return plugin
    }

    /// Creates and inserts a `SystemPlugin` entity with a given name
    ///
    func createSystemPlugin(name: String) -> SystemPlugin {
        let systemPlugin = storage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin.siteID = sampleSiteID
        systemPlugin.name = name
        return systemPlugin
    }
}
