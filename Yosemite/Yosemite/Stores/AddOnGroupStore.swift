import Foundation
import Networking
import Storage

/// Implements actions from `AddOnGroupAction`
///
public final class AddOnGroupStore: Store {

    /// Remote source
    ///
    private let remote: AddOnGroupRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = AddOnGroupRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AddOnGroupAction.self)
    }

    /// Receives and executes actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AddOnGroupAction else {
            assertionFailure("ProductCategoryStore received an unsupported action")
            return
        }

        switch action {
        case let .synchronizeAddOnGroups(siteID, onCompletion):
            break
        }
    }
}
