import Foundation
import Testing

import Fakes
import Storage
@testable import Networking
@testable import Yosemite

@MainActor
struct SystemPluginsUpsertUseCaseTests {
    private let defaultSiteID: Int64 = 10
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
        let activePlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce")
        let inactivePlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "jetpack")

        // When
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [activePlugin], inactivePlugins: [inactivePlugin])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)
        #expect(storedPlugins.count == 2)

        let storedActivePlugin = storedPlugins.first { $0.name == "woocommerce" }
        #expect(storedActivePlugin?.active == true)

        let storedInactivePlugin = storedPlugins.first { $0.name == "jetpack" }
        #expect(storedInactivePlugin?.active == false)
    }

    @Test func upsert_sets_active_state_correctly() async throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", active: false) // Initially false
        let inactivePlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "jetpack", active: true) // Initially true

        // When - pass activePlugin in activePlugins and inactivePlugin in inactivePlugins
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [activePlugin], inactivePlugins: [inactivePlugin])
        }

        // Then - active state should be corrected based on the array they're in
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)

        let storedActivePlugin = storedPlugins.first { $0.name == "woocommerce" }
        #expect(storedActivePlugin?.active == true) // Should be true because it was in activePlugins

        let storedInactivePlugin = storedPlugins.first { $0.name == "jetpack" }
        #expect(storedInactivePlugin?.active == false) // Should be false because it was in inactivePlugins
    }

    @Test func upsert_updates_existing_plugins() async throws {
        // Given
        let originalPlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", version: "1.0.0", active: false)

        // Insert original plugin
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [], inactivePlugins: [originalPlugin])
        }

        // When - update plugin with new version and active state
        let updatedPlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", version: "2.0.0", active: true)
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [updatedPlugin], inactivePlugins: [])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)
        #expect(storedPlugins.count == 1)

        let storedPlugin = storedPlugins.first { $0.name == "woocommerce" }
        #expect(storedPlugin?.version == "2.0.0")
        #expect(storedPlugin?.active == true)
    }

    @Test func upsert_removes_stale_plugins() async throws {
        // Given
        let plugin1 = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", active: true)
        let plugin2 = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "jetpack", active: false)
        let plugin3 = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "yoast", active: true)

        // Insert all three plugins
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [plugin1, plugin3], inactivePlugins: [plugin2])
        }

        // When - only keep plugin1 and plugin2, plugin3 should be removed
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [plugin1], inactivePlugins: [plugin2])
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)
        #expect(storedPlugins.count == 2)

        let pluginNames = storedPlugins.map { $0.name }
        #expect(pluginNames.contains("woocommerce"))
        #expect(pluginNames.contains("jetpack"))
        #expect(!pluginNames.contains("yoast"))
    }

    @Test func upsert_handles_empty_plugin_lists() async throws {
        // Given
        let plugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", active: true)

        // Insert a plugin first
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [plugin], inactivePlugins: [])
        }

        // When - pass empty lists
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [], inactivePlugins: [])
        }

        // Then - all plugins should be removed
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)
        #expect(storedPlugins.count == 0)
    }

    @Test func upsert_handles_site_isolation() async throws {
        // Given
        let plugin1 = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", active: true)
        let plugin2 = SystemPlugin.fake().copy(siteID: 20, name: "jetpack", active: false)

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
        #expect(site1Plugins.first?.name == "woocommerce")
        #expect(site1Plugins.first?.active == true)

        #expect(site2Plugins.count == 1)
        #expect(site2Plugins.first?.name == "jetpack")
        #expect(site2Plugins.first?.active == false)
    }

    @Test func upsert_stores_2_plugins_when_plugin_with_same_name_in_both_active_and_inactive() async throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", version: "1.0.0", active: true)
        let inactivePlugin = SystemPlugin.fake().copy(siteID: defaultSiteID, name: "woocommerce", version: "2.0.0", active: false)

        // When - pass the same plugin name in both active and inactive lists
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: [activePlugin], inactivePlugins: [inactivePlugin])
        }

        // Then - the last one processed should win (inactive in this case)
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)
        #expect(storedPlugins.count == 2)

        let storedActivePlugin = storedPlugins.first { $0.name == "woocommerce" && $0.active == true }
        #expect(storedActivePlugin?.active == true)
        #expect(storedActivePlugin?.version == "1.0.0")

        let storedInactivePlugin = storedPlugins.first { $0.name == "woocommerce" && $0.active == false }
        #expect(storedInactivePlugin?.active == false)
        #expect(storedInactivePlugin?.version == "2.0.0")
    }

    @Test func upsert_handles_large_number_of_plugins() async throws {
        // Given
        let activePlugins = (1...500).map { SystemPlugin.fake().copy(siteID: defaultSiteID, name: "active-plugin-\($0)", active: true) }
        let inactivePlugins = (1...500).map { SystemPlugin.fake().copy(siteID: defaultSiteID, name: "inactive-plugin-\($0)", active: false) }

        // When
        await storageManager.performAndSaveAsync { storage in
            let useCase = SystemPluginsUpsertUseCase(storage: storage)
            useCase.upsert(siteID: defaultSiteID, activePlugins: activePlugins, inactivePlugins: inactivePlugins)
        }

        // Then
        let storedPlugins = viewStorage.loadSystemPlugins(siteID: defaultSiteID)
        #expect(storedPlugins.count == 1000)

        let activeCount = storedPlugins.filter { $0.active }.count
        let inactiveCount = storedPlugins.filter { !$0.active }.count

        #expect(activeCount == 500)
        #expect(inactiveCount == 500)
    }
}
