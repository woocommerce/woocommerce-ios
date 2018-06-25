import Foundation
import Yosemite
import Storage
import Networking



// MARK: - StoresManager
//
class StoresManager {

    /// Shared Instance
    ///
    static var shared = StoresManager(keychain: .shared)

    /// Active StoresManager State.
    ///
    private var state: StoresManagerState {
        didSet {
            state.didEnter()
        }
    }

    /// Credentials Manager: By Reference, for unit testing purposes.
    ///
    private let keychain: CredentialsManager

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    var isAuthenticated: Bool {
        return state is AuthenticatedState
    }


    /// Designated Initializer
    ///
    init(keychain: CredentialsManager) {
        self.state = StoresManager.initialState(from: keychain)
        self.keychain = keychain
    }


    /// Forwards the Action to the current State.
    ///
    func dispatch(_ action: Action) {
        state.onAction(action)
    }


    /// Switches the internal state to Authenticated.
    ///
    func authenticate(username: String, authToken: String) {
        let credentials = Credentials(username: username, authToken: authToken)
        state = AuthenticatedState(keychain: keychain, credentials: credentials)
    }


    /// Switches the state to a Deauthenticated one.
    ///
    func deauthenticate() {
        state = DeauthenticatedState(keychain: keychain)
    }
}


// MARK: - StoresManager Private Methods
//
private extension StoresManager {

    /// Returns the Initial State, depending on whether we've got credentials or not.
    ///
    class func initialState(from keychain: CredentialsManager) -> StoresManagerState {
        guard let credentials = keychain.loadDefaultCredentials() else {
            return DeauthenticatedState(keychain: keychain)
        }

        return AuthenticatedState(keychain: keychain, credentials: credentials)
    }
}


// MARK: - StoresManagerState
//
protocol StoresManagerState {

    /// Executed whenever the State is activated.
    ///
    func didEnter()

    /// Executed whenever an Action is received.
    ///
    func onAction(_ action: Action)
}
