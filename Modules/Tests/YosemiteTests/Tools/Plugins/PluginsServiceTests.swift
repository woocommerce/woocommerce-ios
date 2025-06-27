import Testing
import WooFoundation
@testable import Yosemite

struct PluginsServiceTests {
    private var storageManager: MockStorageManager!
    private var sut: PluginsService!
    private let siteID: Int64 = 134

    init() async throws {
        storageManager = MockStorageManager()
        sut = PluginsService(storageManager: storageManager)
    }

    @Test func waitForPluginInStorage_returns_plugin_when_already_in_storage() async {
        // Given
        await storageManager.reset()
        storageManager.insertWCPlugin(siteID: siteID, isActive: true, version: "1.0.0")

        // When
        let result = await sut.waitForPluginInStorage(siteID: siteID, pluginName: PluginConstants.pluginName, isActive: true)

        // Then
        #expect(result.siteID == siteID)
        #expect(result.name == PluginConstants.pluginName)
        #expect(result.active == true)
        #expect(result.version == "1.0.0")
    }

    @Test func waitForPluginInStorage_waits_to_return_plugin_when_not_in_storage_initially() async {
        // Given
        // Resets any existing state, otherwise test might fail if run multiple times.
        await storageManager.reset()

        // When
        async let plugin = sut.waitForPluginInStorage(siteID: siteID, pluginName: PluginConstants.pluginName, isActive: true)
        #expect(storageManager.viewStorage.loadSystemPlugins(siteID: siteID).count == 0)
        storageManager.insertWCPlugin(siteID: siteID, isActive: true, version: "2.0.0")
        #expect(storageManager.viewStorage.loadSystemPlugins(siteID: siteID).count == 1)

        // Then
        let result = await plugin
        #expect(result.siteID == siteID)
        #expect(result.name == PluginConstants.pluginName)
        #expect(result.active == true)
        #expect(result.version == "2.0.0")
    }
}

private extension MockStorageManager {
    func insertWCPlugin(siteID: Int64, isActive: Bool, version: String? = nil) {
        performAndSave({ storage in
            let plugin = SystemPlugin.fake().copy(siteID: siteID, name: PluginConstants.pluginName, version: version, active: isActive)
            let newPlugin = storage.insertNewObject(ofType: StorageSystemPlugin.self)
            newPlugin.update(with: plugin)
        }, completion: nil, on: .main)
    }

    func reset() async {
        await withCheckedContinuation { continuation in
            reset {
                continuation.resume()
            }
        }
    }
}

// MARK: - Constants
private enum PluginConstants {
    static let pluginName = "Example Plugin"
}
