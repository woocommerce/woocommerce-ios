import Foundation
import Testing

import Fakes
import Storage
import YosemiteTestHelpers
@testable import Networking
@testable import Yosemite

@MainActor
struct SystemPluginsUpsertUseCaseTests {
    private let siteID: Int64 = 10
    private var storageManager: MockStorageManager!
    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    init() async throws {
        storageManager = MockStorageManager()
        storageManager.reset()
    }

    @Test func upsert_inserts_plugins_in_storage() async throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php")
        let inactivePlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "jetpack/jetpack.php")

        // When
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [activePlugin], inactivePlugins: [inactivePlugin])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.count == 2)

        let storedActivePlugin = storedPlugins.first { $0.plugin == "woocommerce/woocommerce.php" }
        #expect(storedActivePlugin?.active == true)

        let storedInactivePlugin = storedPlugins.first { $0.plugin == "jetpack/jetpack.php" }
        #expect(storedInactivePlugin?.active == false)
    }

    @Test func upsert_sets_active_state_correctly() async throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", active: false)
        let inactivePlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "jetpack/jetpack.php", active: true)

        // When - pass activePlugin in activePlugins and inactivePlugin in inactivePlugins
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [activePlugin], inactivePlugins: [inactivePlugin])
        }

        // Then - active state should be corrected based on the array they're in
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)

        let storedActivePlugin = storedPlugins.first { $0.plugin == "woocommerce/woocommerce.php" }
        #expect(storedActivePlugin?.active == true) // Should be true because it was in activePlugins

        let storedInactivePlugin = storedPlugins.first { $0.plugin == "jetpack/jetpack.php" }
        #expect(storedInactivePlugin?.active == false) // Should be false because it was in inactivePlugins
    }

    @Test func upsert_updates_existing_plugins() async throws {
        // Given
        let originalPlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "1.0.0", active: false)

        // Insert original plugin
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [], inactivePlugins: [originalPlugin])
        }

        // When - update plugin with new version and active state
        let updatedPlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "2.0.0", active: true)
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [updatedPlugin], inactivePlugins: [])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.count == 1)

        let storedPlugin = storedPlugins.first { $0.plugin == "woocommerce/woocommerce.php" }
        #expect(storedPlugin?.version == "2.0.0")
        #expect(storedPlugin?.active == true)
    }

    @Test func upsert_removes_stale_plugins() async throws {
        // Given
        let plugin1 = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", active: true)
        let plugin2 = SystemPlugin.fake().copy(siteID: siteID, plugin: "jetpack/jetpack.php", active: false)
        let plugin3 = SystemPlugin.fake().copy(siteID: siteID, plugin: "wordpress-seo/wp-seo.php", active: true)

        // Insert all three plugins
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [plugin1, plugin3], inactivePlugins: [plugin2])
        }

        // When - only keep plugin1 and plugin2, plugin3 should be removed
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [plugin1], inactivePlugins: [plugin2])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.count == 2)

        let pluginPaths = storedPlugins.map { $0.plugin }
        #expect(pluginPaths.contains("woocommerce/woocommerce.php"))
        #expect(pluginPaths.contains("jetpack/jetpack.php"))
        #expect(!pluginPaths.contains("wordpress-seo/wp-seo.php"))
    }

    @Test func upsert_handles_empty_plugin_lists() async throws {
        // Given
        let plugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", active: true)

        // Insert a plugin first
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [plugin], inactivePlugins: [])
        }

        // When - pass empty lists
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [], inactivePlugins: [])
        }

        // Then - all plugins should be removed
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.isEmpty)
    }

    @Test func upsert_handles_site_isolation() async throws {
        // Given
        let plugin1 = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", active: true)
        let plugin2 = SystemPlugin.fake().copy(siteID: 20, plugin: "jetpack/jetpack.php", active: false)

        let siteID1: Int64 = 10
        let siteID2: Int64 = 20

        // When - insert plugins for different sites
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID1, activePlugins: [plugin1], inactivePlugins: [])
            useCase.upsert(siteID: siteID2, activePlugins: [], inactivePlugins: [plugin2])
        }

        // Then - plugins should be isolated by site
        let site1Plugins = viewStorage.loadSystemPlugins(siteID: siteID1)
        let site2Plugins = viewStorage.loadSystemPlugins(siteID: siteID2)

        #expect(site1Plugins.count == 1)
        #expect(site1Plugins.first?.plugin == "woocommerce/woocommerce.php")
        #expect(site1Plugins.first?.active == true)

        #expect(site2Plugins.count == 1)
        #expect(site2Plugins.first?.plugin == "jetpack/jetpack.php")
        #expect(site2Plugins.first?.active == false)
    }

    /// It is possible to have more than one installation of the same plugin, like from using Jetpack Beta
    /// (example p1732109416765569/1732014675.214429-slack-C025A8VV728).
    /// This test and `upsert_stores_all_plugins_per_active_state_when_two_plugins_have_the_same_plugin_path_and_name` ensures that the upsert logic correctly
    /// handles multiple installations of the same plugin.
    @Test func upsert_stores_2_plugins_when_plugin_with_same_name_and_plugin_path_in_both_active_and_inactive() async throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "1.0.0", active: true)
        let inactivePlugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "2.0.0", active: false)

        // When
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [activePlugin], inactivePlugins: [inactivePlugin])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.count == 2)

        let storedActivePlugin = storedPlugins.first { $0.plugin == "woocommerce/woocommerce.php" && $0.active == true }
        #expect(storedActivePlugin?.active == true)
        #expect(storedActivePlugin?.version == "1.0.0")

        let storedInactivePlugin = storedPlugins.first { $0.plugin == "woocommerce/woocommerce.php" && $0.active == false }
        #expect(storedInactivePlugin?.active == false)
        #expect(storedInactivePlugin?.version == "2.0.0")
    }

    @Test func upsert_stores_all_plugins_per_active_state_when_two_plugins_have_the_same_plugin_path_and_name() async throws {
        // Given
        let activePlugin1 = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "1.0.0", active: true)
        let activePlugin2 = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "1.1.0", active: true)
        let inactivePlugin1 = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "2.0.0", active: false)
        let inactivePlugin2 = SystemPlugin.fake().copy(siteID: siteID, plugin: "woocommerce/woocommerce.php", version: "2.5.0", active: false)

        // When
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: [activePlugin1, activePlugin2], inactivePlugins: [inactivePlugin1, inactivePlugin2])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.count == 4)

        let storedActivePlugins = storedPlugins.filter { $0.plugin == "woocommerce/woocommerce.php" && $0.active == true }
        #expect(Set(storedActivePlugins.map { $0.version }) == ["1.0.0", "1.1.0"])

        let storedInactivePlugins = storedPlugins.filter { $0.plugin == "woocommerce/woocommerce.php" && $0.active == false }
        #expect(Set(storedInactivePlugins.map { $0.version }) == ["2.0.0", "2.5.0"])
    }

    @Test func upsert_handles_large_number_of_plugins() async throws {
        // Given
        let activePlugins = (1...500).map {
            SystemPlugin.fake().copy(siteID: siteID, plugin: "active-plugin-\($0)/plugin.php", active: true)
        }
        let inactivePlugins = (1...500).map {
            SystemPlugin.fake().copy(siteID: siteID, plugin: "inactive-plugin-\($0)/plugin.php", active: false)
        }

        // When
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: siteID, activePlugins: activePlugins, inactivePlugins: inactivePlugins)
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: siteID)
        #expect(storedPlugins.count == 1000)

        let activeCount = storedPlugins.filter { $0.active }.count
        let inactiveCount = storedPlugins.filter { !$0.active }.count

        #expect(activeCount == 500)
        #expect(inactiveCount == 500)
    }
}
