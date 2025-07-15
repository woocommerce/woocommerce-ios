import Foundation
import Storage
import Networking

/// Upserts `Networking.SystemPlugin` objects into Storage.
///
/// This UseCase encapsulates the business logic for inserting or updating system plugins,
/// including handling active/inactive state and removing stale plugins.
struct SystemPluginsUpsertUseCase {
    private let storage: StorageType

    /// Initializes a new UseCase.
    ///
    /// - Parameter storage: A derived `StorageType`.
    init(storage: StorageType) {
        self.storage = storage
    }

    /// Updates or inserts the given system plugins for a site.
    ///
    /// - Parameters:
    ///   - siteID: The site ID these plugins belong to.
    ///   - activePlugins: Array of active system plugins.
    ///   - inactivePlugins: Array of inactive system plugins.
    ///
    func upsert(siteID: Int64, activePlugins: [SystemPlugin], inactivePlugins: [SystemPlugin]) {
        // Active and inactive plugins share identical structure, but are stored in separate parts of the remote response
        // (and without an active attribute in the response). So we apply the correct value for active (or not).
        let readonlySystemPlugins: [SystemPlugin] = {
            let activePluginsWithState = activePlugins.map {
                $0.copy(active: true)
            }

            let inactivePluginsWithState = inactivePlugins.map {
                $0.copy(active: false)
            }

            return activePluginsWithState + inactivePluginsWithState
        }()

        let storedPlugins = storage.loadSystemPlugins(siteID: siteID, matchingPaths: readonlySystemPlugins.map { $0.plugin })
        readonlySystemPlugins.forEach { readonlySystemPlugin in
            // Loads or creates new StorageSystemPlugin matching the readonly one.
            let storageSystemPlugin: StorageSystemPlugin = {
                if let systemPlugin = storedPlugins.first(where: { $0.plugin == readonlySystemPlugin.plugin }) {
                    return systemPlugin
                }
                return storage.insertNewObject(ofType: StorageSystemPlugin.self)
            }()

            storageSystemPlugin.update(with: readonlySystemPlugin)
        }

        // Removes stale system plugins.
        let currentSystemPluginPaths = readonlySystemPlugins.map(\.plugin)
        storage.deleteStaleSystemPlugins(siteID: siteID, currentSystemPluginPaths: currentSystemPluginPaths)
    }
}
