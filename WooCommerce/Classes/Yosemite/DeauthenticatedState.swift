import Foundation
import Yosemite



// MARK: - DeauthenticatedState
//
class DeauthenticatedState: StoresManagerState {

    /// This method should run only when the app got deauthenticated.
    ///
    func didEnter() {
        AppDelegate.shared.displayAuthenticator(animated: true)
    }

    /// NO-OP: Executed before the current state is deactivated.
    ///
    func willLeave() { }

    /// NO-OP: During deauth method, we're not running any actions.
    ///
    func onAction(_ action: Action) { }
}
