import Foundation
import WooFoundation
import protocol Storage.StorageManagerType

/// A service for system plugins.
public protocol PluginsServiceProtocol {
    /// Waits for a specific plugin to be available in storage.
    /// - Parameters:
    ///   - siteID: The site ID to search for the plugin.
    ///   - pluginPath: The plugin's file path (e.g., "woocommerce/woocommerce.php" for WooCommerce).
    ///   - isActive: Whether the plugin is active or not.
    /// - Returns: The SystemPlugin when found in storage.
    func waitForPluginInStorage(siteID: Int64, pluginPath: String, isActive: Bool) async -> SystemPlugin

    /// Loads a specific plugin from storage synchronously.
    /// - Parameters:
    ///   - siteID: The site ID to search for the plugin.
    ///   - plugin: The plugin to load.
    ///   - isActive: Whether the plugin is active, inactive, or nil for any state.
    /// - Returns: The SystemPlugin if found in storage, nil otherwise.
    func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin?
}

public extension PluginsServiceProtocol {
    func isPluginActiveInStorage(siteID: Int64, plugin: Plugin) -> Bool {
        let plugin = loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true)
        return plugin != nil && plugin?.active == true
    }
}

public class PluginsService: PluginsServiceProtocol {
    private let storageManager: StorageManagerType

    public init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    @MainActor
    public func waitForPluginInStorage(siteID: Int64, pluginPath: String, isActive: Bool) async -> SystemPlugin {
        let predicate = \StorageSystemPlugin.siteID == siteID && \StorageSystemPlugin.plugin == pluginPath && \StorageSystemPlugin.active == isActive
        let pluginDescriptor = NSSortDescriptor(keyPath: \StorageSystemPlugin.plugin, ascending: true)
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storageManager,
                                                                       matching: predicate,
                                                                       fetchLimit: 1,
                                                                       sortedBy: [pluginDescriptor])
        do {
            try resultsController.performFetch()
            if let plugin = resultsController.fetchedObjects.first {
                return plugin
            }
        } catch {
            DDLogError("Error loading plugin \(pluginPath) for site \(siteID) initially: \(error.localizedDescription)")
        }

        return await withCheckedContinuation { continuation in
            var hasResumed = false
            resultsController.onDidChangeContent = {
                guard let plugin = resultsController.fetchedObjects.first,
                      !hasResumed else {
                    return
                }
                hasResumed = true
                continuation.resume(returning: plugin)
            }
        }
    }

    public func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin? {
        storageManager.viewStorage.loadSystemPlugin(siteID: siteID,
                                                    fileNameWithoutExtension: plugin.fileNameWithoutExtension,
                                                    active: isActive)?.toReadOnly()
    }
}
