import Foundation
import Yosemite

final class PluginListViewModel {

    /// Whether synchronization failed and error state should be displayed
    ///
    @Published var pluginListState: PluginListState = .results

    /// ID of the site to load plugins for
    ///
    private let siteID: Int64

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    /// Results controller for the plugin list
    ///
    private lazy var resultsController: ResultsController<StorageSitePlugin> = {
        let storage = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld", self.siteID)
        let nameDescriptor = NSSortDescriptor(keyPath: \StorageSitePlugin.name, ascending: true)
        let statusDescriptor = NSSortDescriptor(keyPath: \StorageSitePlugin.status, ascending: true)
        return ResultsController<StorageSitePlugin>(
            storageManager: storage,
            sectionNameKeyPath: "status",
            matching: predicate,
            sortedBy: [nameDescriptor, statusDescriptor]
        )
    }()

    init(siteID: Int64, storesManager: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.storesManager = storesManager
    }

    /// Start fetching plugin data from local storage.
    ///
    func activate() {
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching plugin list!")
        }
    }

    /// Manually resync plugin list.
    ///
    func resyncPlugins(onComplete: @escaping () -> Void) {
        pluginListState = .syncing
        let action = SitePluginAction.synchronizeSitePlugins(siteID: siteID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.pluginListState = .results
            case .failure:
                self.pluginListState = .error
            }
            onComplete()
        }
        storesManager.dispatch(action)
    }
}

// MARK: - Table view data source
//
extension PluginListViewModel {
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
        let sectionTitle: String
        switch pluginStatus {
        case .active:
            sectionTitle = NSLocalizedString("Active Plugins", comment: "Title for table view section of active plugins")
        case .inactive:
            sectionTitle = NSLocalizedString("Inactive Plugins", comment: "Title for table view section of inactive plugins")
        case .networkActive:
            sectionTitle = NSLocalizedString("Network Active Plugins", comment: "Title for table view section of network active plugins")
        case .unknown:
            sectionTitle = "" // This case should not happen
        }
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
        // since raw description still randomly contains HTML tags
        // it's best to remove it just to be sure
        return PluginListCellViewModel(name: plugin.name, description: plugin.descriptionRaw.removedHTMLTags)
    }
}

// MARK: - Nested Types
//
extension PluginListViewModel {
    /// States for the Plugin List screen
    ///
    enum PluginListState {
        case results
        case syncing
        case error
    }
}
