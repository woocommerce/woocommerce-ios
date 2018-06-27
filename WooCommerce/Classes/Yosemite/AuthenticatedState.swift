import Foundation
import Yosemite
import Storage
import Networking



// MARK: - AuthenticatedState
//
class AuthenticatedState: StoresManagerState {

    /// Active Credentials
    ///
    private let credentials: Credentials

    /// Dispatcher: Glues all of the Stores!
    ///
    private let dispatcher = Dispatcher()

    /// Retains all of the active Services
    ///
    private let services: [ActionsProcessor]

    /// CredentialsManager: By Reference, for unit testing purposes.
    ///
    private let keychain: CredentialsManager



    /// Designated Initializer
    ///
    init(keychain: CredentialsManager, credentials: Credentials) {
        let storageManager = CoreDataManager.global
        let network = AlamofireNetwork(credentials: credentials)

        services = [
            AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        ]

        self.credentials = credentials
        self.keychain = keychain
    }


    /// Executed whenever the state is activated.
    ///
    func didEnter() {
        keychain.saveDefaultCredentials(credentials)
    }


    /// Forwards the received action to the Actions Dispatcher.
    ///
    func onAction(_ action: Action) {
        dispatcher.dispatch(action)
    }
}
