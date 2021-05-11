import Foundation
import Yosemite

final class PluginListViewModel {

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    init(storesManager: StoresManager = ServiceLocator.stores) {
        self.storesManager = storesManager
    }
}
