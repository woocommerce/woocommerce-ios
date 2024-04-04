import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class PluginListViewModel {

    /// ID of the site to load plugins for
    ///
    private let siteID: Int64

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    /// StorageManager to load plugins from storage
    ///
    private let storageManager: StorageManagerType

    /// Results controller for the plugin list
    ///
    private lazy var resultsController: ResultsController<StorageSystemPlugin> = {
        let predicate = NSPredicate(format: "siteID = %ld", self.siteID)
        let nameDescriptor = NSSortDescriptor(keyPath: \StorageSystemPlugin.name, ascending: true)
        let resultsController = ResultsController<StorageSystemPlugin>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [nameDescriptor]
        )

        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching plugin list!")
        }
        return resultsController
    }()

    var pluginNameList: [String] {
        // Plugin name can sometimes contain HTML tags and entities
        resultsController.fetchedObjects.map { $0.name.strippedHTML }
    }

    init(siteID: Int64,
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.storageManager = storageManager

        trackOutOfDatePluginsIfAny()
    }

    /// Start fetching and observing plugin data from local storage.
    ///
    func observePlugins(onDataChanged: @escaping () -> Void) {
        resultsController.onDidChangeContent = onDataChanged
    }

    /// Manually sync plugins.
    ///
    func syncPlugins(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = SitePluginAction.synchronizeSitePlugins(siteID: siteID, onCompletion: onCompletion)
        storesManager.dispatch(action)
    }
}

private extension PluginListViewModel {
    /// Tracks outdated plugins and their versions, if any
    ///
    func trackOutOfDatePluginsIfAny() {
        let outOfDatePlugins = resultsController.fetchedObjects.filter { $0.version != $0.versionLatest }
        guard outOfDatePlugins.isNotEmpty else {
            return
        }
        let pluginNamesAndVersions = outOfDatePlugins.map { "\($0.name) - \($0.version)" }.joined(separator: ", ")
        ServiceLocator.analytics.track(event: .logOutOfDatePlugins(outOfDatePlugins.count, pluginNamesAndVersions))
    }
}
