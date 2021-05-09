import Foundation
import Yosemite

final class PluginListViewModel {

    /// Whether synchronization failed and error state should be displayed
    ///
    @Published var shouldShowErrorState: Bool = false

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
    func resyncPlugins() {
        let action = SitePluginAction.synchronizeSitePlugins(siteID: siteID) { [weak self] result in
            self?.shouldShowErrorState = result.isFailure
        }
        storesManager.dispatch(action)
    }
}

extension PluginListViewModel {
    /// Number of sections to display on the table view.
    ///
    var numberOfSections: Int {
        resultsController.sections.count
    }

    /// Title of table view section at specified index.
    ///
    func titleForSection(at index: Int) -> String? {
        resultsController.sections[safe: index]?.name.capitalized
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
        return PluginListCellViewModel(name: plugin.name, description: plugin.descriptionRaw)
    }
 }
