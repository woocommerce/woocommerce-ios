import Testing
import WooFoundation
import YosemiteTestHelpers
@testable import Yosemite

@MainActor
struct PluginsServiceTests {
    private var storageManager: MockStorageManager!
    private var sut: PluginsService!
    private let siteID: Int64 = 134

    init() async throws {
        storageManager = MockStorageManager()
        sut = PluginsService(storageManager: storageManager)
    }

    // MARK: - `loadPluginInStorage`

    @Test(arguments: [(Plugin.wooCommerce, true, "1.5.0"),
                      (Plugin.wooCommerce, false, "2.1.0"),
                      (Plugin.wooSubscriptions, true, "3.0.0"),
                      (Plugin.wooShipmentTracking, false, "3.0.0")])
    func loadPluginInStorage_returns_plugin_when_exists_in_storage(plugin: Plugin, isActive: Bool, version: String) async throws {
        // Given
        await storageManager.reset()
        storageManager.insertPlugin(siteID: siteID, plugin: plugin, isActive: isActive, version: version)

        // When
        let result = sut.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: isActive)

        // Then
        let unwrappedResult = try #require(result)
        #expect(unwrappedResult.siteID == siteID)
        #expect(unwrappedResult.plugin == plugin.pluginPath)
        #expect(unwrappedResult.active == isActive)
        #expect(unwrappedResult.version == version)
    }

    @Test func loadPluginInStorage_returns_plugin_when_exists_in_storage_with_any_active_state() async throws {
        // Given
        await storageManager.reset()
        storageManager.insertPlugin(siteID: siteID, plugin: .wooCommerce, isActive: true, version: "3.0.0")

        // When
        let result = sut.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: nil)

        // Then
        let unwrappedResult = try #require(result)
        #expect(unwrappedResult.siteID == siteID)
        #expect(unwrappedResult.plugin == "woocommerce/woocommerce.php")
        #expect(unwrappedResult.active == true)
        #expect(unwrappedResult.version == "3.0.0")
    }

    @Test func loadPluginInStorage_returns_nil_when_plugin_does_not_exist() async {
        // Given
        await storageManager.reset()

        // When
        let result = sut.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: true)

        // Then
        #expect(result == nil)
    }

    @Test func loadPluginInStorage_returns_nil_when_plugin_exists_but_active_state_does_not_match() async {
        // Given
        await storageManager.reset()
        storageManager.insertPlugin(siteID: siteID, plugin: .wooCommerce, isActive: true, version: "1.0.0")

        // When
        let result = sut.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: false)

        // Then
        #expect(result == nil)
    }

    @Test func loadPluginInStorage_returns_nil_when_plugin_exists_for_different_site() async {
        // Given
        await storageManager.reset()
        let differentSiteID: Int64 = 999
        storageManager.insertPlugin(siteID: differentSiteID, plugin: .wooCommerce, isActive: true, version: "1.0.0")

        // When
        let result = sut.loadPluginInStorage(siteID: siteID, plugin: .wooCommerce, isActive: true)

        // Then
        #expect(result == nil)
    }
}

private extension MockStorageManager {
    func insertPlugin(siteID: Int64, plugin: Plugin, isActive: Bool, version: String? = nil) {
        performAndSave({ storage in
            let systemPlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                        plugin: plugin.pluginPath,
                                                        version: version,
                                                        active: isActive)
            let newPlugin = storage.insertNewObject(ofType: StorageSystemPlugin.self)
            newPlugin.update(with: systemPlugin)
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

extension Plugin {
    var pluginPath: String {
        "\(fileNameWithoutExtension)/\(fileNameWithoutExtension).php"
    }
}
