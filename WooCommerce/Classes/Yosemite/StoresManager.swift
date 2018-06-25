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
protocol StoresManagerState {

    /// Executed whenever the State is activated.
    ///
    func didEnter()

    /// Executed whenever an Action is received.
    ///
    func onAction(_ action: Action)
}
