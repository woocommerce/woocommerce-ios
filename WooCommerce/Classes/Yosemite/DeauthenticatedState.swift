import Foundation
import Yosemite
import class Networking.AlamofireNetwork

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
        // Used for logged-out state without a WPCOM auth token.
        let network = AlamofireNetwork(credentials: nil)
        services = [
            JetpackConnectionStore(dispatcher: dispatcher),
            AccountCreationStore(dotcomClientID: ApiCredentials.dotcomAppId,
                                 dotcomClientSecret: ApiCredentials.dotcomSecret,
                                 network: network,
                                 dispatcher: dispatcher),
            WordPressSiteStore(network: network, dispatcher: dispatcher)
        ]
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
