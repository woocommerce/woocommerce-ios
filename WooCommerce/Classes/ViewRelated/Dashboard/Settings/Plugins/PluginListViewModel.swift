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

    func syncPlugins() {
        let action = SitePluginAction.synchronizeSitePlugins(siteID: siteID) { [weak self] result in
            self?.shouldShowErrorState = result.isFailure
        }
        storesManager.dispatch(action)
    }
}
