import Foundation
import Yosemite



// MARK: - DeauthenticatedState
//
class DeauthenticatedState: StoresManagerState {

    /// This method should run only when the app got deauthenticated.
    ///
    func didEnter() {
        CredentialsManager.shared.removeDefaultCredentials()
        AppDelegate.shared.displayAuthenticator()
    }


    /// NO-OP: During deauth method, we're not running any actions.
    ///
    func onAction(_ action: Action) { }
}
