import Foundation
import Networking
import Storage

// Handles `UserAction` actions in unauthenticated state
//
public final class DeauthenticatedUserStore: DeauthenticatedStore {
    private var remote: UserRemote?

    public override init(dispatcher: Dispatcher) {
        super.init(dispatcher: dispatcher)
    }

    /// Registers to support `UserAction`
    ///
    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: UserAction.self)
    }

    /// Receives and executes actions
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? DeauthenticatedUserAction else {
            assertionFailure("UserStore receives an unsupported action!")
            return
        }

        switch action {
        case .authenticate(let network):
            updateRemote(network: network)
        case let .retrieveUser(siteURL, onCompletion):
            retrieveUser(siteURL: siteURL, completionHandler: onCompletion)
        }
    }
}

// MARK: - Network request
//
private extension DeauthenticatedUserStore {
    func updateRemote(network: Network) {
        self.remote = UserRemote(network: network)
    }

    func retrieveUser(siteURL: String, completionHandler: @escaping (Result<User, Error>) -> Void) {
        remote?.loadUserInfo(for: siteURL, completion: completionHandler)
    }
}
