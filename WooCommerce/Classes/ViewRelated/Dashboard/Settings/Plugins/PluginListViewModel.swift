import Foundation
import Yosemite

final class PluginListViewModel {

    /// Whether synchronization failed and error state should be displayed
    ///
    @Published var shouldShowErrorState: Bool = false

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    init(storesManager: StoresManager = ServiceLocator.stores) {
        self.storesManager = storesManager
    }

    func syncPlugins() {
        guard let id = storesManager.sessionManager.defaultStoreID else {
            return
        }
        let action = SitePluginAction.synchronizeSitePlugins(siteID: id) { [weak self] result in
            self?.shouldShowErrorState = result.isFailure
        }
        storesManager.dispatch(action)
    }
}
