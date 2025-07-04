import Foundation
import WooFoundation
import protocol Storage.StorageManagerType

/// A service for system plugins.
public protocol PluginsServiceProtocol {
    /// Waits for a specific plugin to be available in storage.
    /// - Parameters:
    ///   - siteID: The site ID to search for the plugin.
    ///   - plugin: The plugin's file path (e.g., "woocommerce/woocommerce.php" for WooCommerce).
    ///   - isActive: Whether to wait for the plugin to be active or inactive.
    /// - Returns: The SystemPlugin when found in storage.
    func waitForPluginInStorage(siteID: Int64, plugin: String, isActive: Bool) async -> SystemPlugin
}

public class PluginsService: PluginsServiceProtocol {
    private let storageManager: StorageManagerType

    public init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    @MainActor
    public func waitForPluginInStorage(siteID: Int64, plugin: String, isActive: Bool) async -> SystemPlugin {
        let predicate = \StorageSystemPlugin.siteID == siteID && \StorageSystemPlugin.plugin == plugin && \StorageSystemPlugin.active == isActive
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
            DDLogError("Error loading plugin \(plugin) for site \(siteID) initially: \(error.localizedDescription)")
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
}
