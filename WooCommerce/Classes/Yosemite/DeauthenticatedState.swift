import Foundation
import Yosemite
import protocol Networking.Network

// MARK: - DeauthenticatedState
//
class DeauthenticatedState: StoresManagerState {
    /// Dispatcher: Glues all of the Stores!
    ///
    private let dispatcher = Dispatcher()

    /// Retains all of the active Services
    ///
    private let services: [DeauthenticatedStore]

    init() {
        services = [JetpackConnectionStore(dispatcher: dispatcher)]
    }

    /// Asks the persisted stores to update their remote with the given siteURL and network.
    ///
    func updateStores(with siteURL: String, network: Network) {
        for store in services {
            store.updateRemote(with: siteURL, network: network)
        }
    }

    /// NO-OP: Executed when current state is activated.
    ///
    func didEnter() { }

    /// NO-OP: Executed before the current state is deactivated.
    ///
    func willLeave() { }

    /// During deauth method, we're handling actions that don't require access token to WordPress.com.
    ///
    func onAction(_ action: Action) {
        dispatcher.dispatch(action)
    }
}
