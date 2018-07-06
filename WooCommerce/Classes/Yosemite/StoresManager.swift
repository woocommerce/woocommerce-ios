import Foundation
import Yosemite



// MARK: - StoresManager
//
class StoresManager {

    /// Shared Instance
    ///
    static var shared = StoresManager(sessionManager: .standard)

    /// SessionManager: Persistent Storage for Session-Y Properties.
    ///
    private(set) var sessionManager: SessionManager

    /// Active StoresManager State.
    ///
    private var state: StoresManagerState = DeauthenticatedState() {
        didSet {
            state.didEnter()
        }
    }

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    var isAuthenticated: Bool {
        return state is AuthenticatedState
    }


    /// Designated Initializer
    ///
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        authenticateIfPossible()
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

        state = AuthenticatedState(credentials: credentials)
        sessionManager.credentials = credentials
    }


    /// Switches the state to a Deauthenticated one.
    ///
    func deauthenticate() {
        state = DeauthenticatedState()
        sessionManager.reset()
    }
}


// MARK: - StoresManager Private Methods
//
private extension StoresManager {

    /// Switches over to the AuthenticatedState whenever needed / possible!.
    ///
    func authenticateIfPossible() {
        guard let credentials = sessionManager.credentials else {
            return
        }

        state = AuthenticatedState(credentials: credentials)
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
