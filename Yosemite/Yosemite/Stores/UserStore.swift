import Foundation
import Networking
import Storage

// Handles `UserAction` actions
//
public final class UserStore: Store {
    private let remote: UserRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = UserRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers to support `UserAction`
    ///
    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: UserAction.self)
    }

    /// Receives and executes actions
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? UserAction else {
            assertionFailure("UserStore receives an unsupported action!")
            return
        }

        switch action {
        case .retrieveUser(let siteID, let onCompletion):
            retrieveUser(siteID: siteID, completionHandler: onCompletion)
        }
    }
}

// MARK: - Network request
//
private extension UserStore {
    func retrieveUser(siteID: Int64, completionHandler: @escaping (Result<User, Error>) -> Void) {
        remote.loadUserInfo(for: siteID, completion: completionHandler)
    }
}
