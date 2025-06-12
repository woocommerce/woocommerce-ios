import Foundation
import WooFoundation
import protocol Storage.StorageManagerType

/// A service for system plugins.
public protocol PluginsServiceProtocol {
    /// Waits for a specific plugin to be available in storage.
    func waitForPluginInStorage(siteID: Int64, pluginName: String, isActive: Bool) async -> SystemPlugin
}

public class PluginsService: PluginsServiceProtocol {
    private let storageManager: StorageManagerType

    public init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    @MainActor
    public func waitForPluginInStorage(siteID: Int64, pluginName: String, isActive: Bool) async -> SystemPlugin {
        let predicate = \StorageSystemPlugin.siteID == siteID && \StorageSystemPlugin.name == pluginName && \StorageSystemPlugin.active == isActive
        let nameDescriptor = NSSortDescriptor(keyPath: \StorageSystemPlugin.name, ascending: true)
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storageManager,
                                                                       matching: predicate,
                                                                       fetchLimit: 1,
                                                                       sortedBy: [nameDescriptor])
        do {
            try resultsController.performFetch()
            if let plugin = resultsController.fetchedObjects.first {
                return plugin
            }
        } catch {
            DDLogError("Error loading plugin \(pluginName) for site \(siteID) initially: \(error.localizedDescription)")
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
