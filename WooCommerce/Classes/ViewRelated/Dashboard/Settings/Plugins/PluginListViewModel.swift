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
