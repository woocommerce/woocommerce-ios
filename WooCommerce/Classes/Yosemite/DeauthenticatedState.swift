import Foundation
import Yosemite



// MARK: - DeauthenticatedState
//
class DeauthenticatedState: StoresManagerState {

    /// CredentialsManager: By Reference, for unit testing purposes.
    ///
    private let keychain: CredentialsManager


    /// Designated Initializer
    ///
    init(keychain: CredentialsManager) {
        self.keychain = keychain
    }

    /// This method should run only when the app got deauthenticated.
    ///
    func didEnter() {
        keychain.removeDefaultCredentials()
        AppDelegate.shared.displayAuthenticator()
    }


    /// NO-OP: During deauth method, we're not running any actions.
    ///
    func onAction(_ action: Action) { }
}
