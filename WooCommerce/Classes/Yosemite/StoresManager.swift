import Foundation
import Yosemite
import Storage
import Networking



// MARK: - StoresManager
//
class StoresManager {

    /// Active (Internal) State.
    ///
    private static var state: StoresManagerState = initialState() {
        didSet {
            state.didEnter()
        }
    }

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    static var isAuthenticated: Bool {
        return state is AuthenticatedState
    }


    /// This class is meant to be non (publicly) instantiable!
    ///
    private init() { }


    /// Forwards the Action to the current State.
    ///
    class func dispatch(_ action: Action) {
        state.onAction(action)
    }


    /// Switches the internal state to Authenticated.
    ///
    class func authenticate(username: String, authToken: String) {
        let credentials = Credentials(username: username, authToken: authToken)
        state = AuthenticatedState(credentials: credentials)
    }


    /// Switches the state to a Deauthenticated one.
    ///
    class func deauthenticate() {
        state = DeauthenticatedState()
    }
}


// MARK: - StoresManager Private Methods
//
private extension StoresManager {

    /// Returns the Initial State, depending on whether we've got credentials or not.
    ///
    class func initialState() -> StoresManagerState {
        guard let credentials = CredentialsManager.shared.loadDefaultCredentials() else {
            return DeauthenticatedState()
        }

        return AuthenticatedState(credentials: credentials)
    }
}


// MARK: - StoresManagerState
//
private protocol StoresManagerState {

    /// Executed whenever the State is activated.
    ///
    func didEnter()

    /// Executed whenever an Action is received.
    ///
    func onAction(_ action: Action)
}



// MARK: - DeauthenticatedState
//
private class DeauthenticatedState: StoresManagerState {

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



// MARK: - AuthenticatedState
//
private class AuthenticatedState: StoresManagerState {

    /// Active Credentials
    ///
    private let credentials: Credentials

    /// Dispatcher: Glues all of the Stores!
    ///
    private let dispatcher = Dispatcher()

    /// Retains all of the active Services
    ///
    private let services: [ActionsProcessor]


    /// Designated Initializer
    ///
    init(credentials: Credentials) {
        let storageManager = CoreDataManager.global
        let network = AlamofireNetwork(credentials: credentials)

        services = [
            AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        ]

        self.credentials = credentials
    }


    /// Executed whenever the state is activated.
    ///
    func didEnter() {
        CredentialsManager.shared.saveDefaultCredentials(credentials)
    }


    /// Forwards the received action to the Actions Dispatcher.
    ///
    func onAction(_ action: Action) {
        dispatcher.dispatch(action)
    }
}
