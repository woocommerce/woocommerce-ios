import Foundation
import protocol Storage.StorageManagerType

/// A service for system plugins.
public protocol PluginsServiceProtocol {
    /// Loads a specific plugin from storage synchronously.
    /// - Parameters:
    ///   - siteID: The site ID to search for the plugin.
    ///   - plugin: The plugin to load.
    ///   - isActive: Whether the plugin is active, inactive, or nil for any state.
    /// - Returns: The SystemPlugin if found in storage, nil otherwise.
    @MainActor
    func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin?
}

public extension PluginsServiceProtocol {
    @MainActor
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
    public func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin? {
        storageManager.viewStorage.loadSystemPlugin(siteID: siteID,
                                                    fileNameWithoutExtension: plugin.fileNameWithoutExtension,
                                                    active: isActive)?.toReadOnly()
    }
}
