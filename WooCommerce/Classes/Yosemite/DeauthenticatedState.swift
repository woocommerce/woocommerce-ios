import Foundation
import Yosemite



// MARK: - DeauthenticatedState
//
class DeauthenticatedState: StoresManagerState {
    /// Dispatcher: Glues all of the Stores!
    ///
    private let dispatcher = Dispatcher()

    /// Retains all of the active Services
    ///
    private let services: [ActionsProcessor]

    init() {
        services = [JetpackConnectionStore(dispatcher: dispatcher)]
    }

    /// NO-OP: Executed when current state is activated.
    ///
    func didEnter() { }

    /// NO-OP: Executed before the current state is deactivated.
    ///
    func willLeave() { }

    /// During deauth method, we're not handling actions that don't require access token.
    ///
    func onAction(_ action: Action) {
        dispatcher.dispatch(action)
    }
}
