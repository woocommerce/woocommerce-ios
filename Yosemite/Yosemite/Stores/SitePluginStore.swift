import Foundation
import Networking
import Storage

// Handles `SitePluginAction` actions
//
public final class SitePluginStore: Store {
    private let remote: SitePluginsRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = SitePluginsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers to support `SitePluginAction`
    ///
    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SitePluginAction.self)
    }

    /// Receives and executes actions
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? SitePluginAction else {
            assertionFailure("SitePluginStore receives an unsupported action!")
            return
        }

        switch action {
        case .synchronizeSitePlugins(let siteID, let onCompletion):
            break
        }
    }
}
