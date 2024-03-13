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

// MARK: - Data source for plugin list
//
extension PluginListViewModel {
    /// Title for the Plugin List screen
    ///
    var pluginListTitle: String {
        Localization.pluginListTitle
    }

    /// Message for the error state of the Plugin List screen.
    ///
    var errorStateMessage: String {
        Localization.errorStateMessage
    }

    /// Details for the error state of the Plugin List screen.
    ///
    var errorStateDetails: String {
        Localization.errorStateDetails
    }

    /// Action title for the error state of the Plugin List screen.
    ///
    var errorStateActionTitle: String {
        Localization.errorStateAction
    }
}

// MARK: - Localization
//
private extension PluginListViewModel {
    enum Localization {
        static let pluginListTitle = NSLocalizedString("Plugins", comment: "Title of the Plugin List screen")
        static let activeSectionTitle = NSLocalizedString("Active Plugins", comment: "Title for table view section of active plugins")
        static let inactiveSectionTitle = NSLocalizedString("Inactive Plugins", comment: "Title for table view section of inactive plugins")
        static let networkActiveSectionTitle = NSLocalizedString("Network Active Plugins", comment: "Title for table view section of network active plugins")
        static let errorStateMessage = NSLocalizedString("Something went wrong",
                                                         comment: "The text on the placeholder overlay when there is issue syncing site plugins")
        static let errorStateDetails = NSLocalizedString("There was a problem while trying to load plugins. Check your internet and try again.",
                                                         comment: "The details on the placeholder overlay when there is issue syncing site plugins")
        static let errorStateAction = NSLocalizedString("Try again",
                                                        comment: "Action to resync on the placeholder overlay when there is issue syncing site plugins")
    }
}

// MARK: - Model for plugin list cells
//
struct PluginListCellViewModel {
    let name: String
    let description: String
 }
