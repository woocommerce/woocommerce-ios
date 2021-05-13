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
    private lazy var resultsController: ResultsController<StorageSitePlugin> = {
        let predicate = NSPredicate(format: "siteID = %ld", self.siteID)
        let nameDescriptor = NSSortDescriptor(keyPath: \StorageSitePlugin.name, ascending: true)
        // Results need to be grouped in sections so sorting by section is required.
        // Make sure this sort descriptor is first in the list to make grouping works.
        let statusDescriptor = NSSortDescriptor(keyPath: \StorageSitePlugin.status, ascending: true)
        return ResultsController<StorageSitePlugin>(
            storageManager: storageManager,
            sectionNameKeyPath: "status",
            matching: predicate,
            sortedBy: [statusDescriptor, nameDescriptor]
        )
    }()

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
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching plugin list!")
        }

        resultsController.onDidChangeContent = onDataChanged
    }

    /// Manually resync plugins.
    ///
    func resyncPlugins(onCompletion: @escaping (Result<Void, Error>) -> Void) {
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

    /// Number of sections to display on the table view.
    ///
    var numberOfSections: Int {
        resultsController.sections.count
    }

    /// Title of table view section at specified index.
    ///
    func titleForSection(at index: Int) -> String? {
        guard let rawStatus = resultsController.sections[safe: index]?.name else {
            return nil
        }
        let pluginStatus = SitePluginStatusEnum(rawValue: rawStatus)
        let sectionTitle: String = {
            switch pluginStatus {
            case .active:
                return Localization.activeSectionTitle
            case .inactive:
                return Localization.inactiveSectionTitle
            case .networkActive:
                return Localization.networkActiveSectionTitle
            case .unknown:
                return "" // This case should not happen
            }
        }()
        return sectionTitle.capitalized
    }

    /// Number of rows in a specified table view section index.
    ///
    func numberOfRows(inSection sectionIndex: Int) -> Int {
        resultsController.sections[safe: sectionIndex]?.objects.count ?? 0
    }

    /// View model for the table view cell at specified index path.
    ///
    func cellModelForRow(at indexPath: IndexPath) -> PluginListCellViewModel {
        let plugin = resultsController.object(at: indexPath)
        // Plugin name and description can sometimes contain HTML tags and entities
        // so it's best to be extra safe by removing them
        return PluginListCellViewModel(
            name: plugin.name.strippedHTML,
            description: plugin.descriptionRaw.strippedHTML
        )
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
    }
}

// MARK: - Model for plugin list cells
//
struct PluginListCellViewModel {
     let name: String
     let description: String
 }
